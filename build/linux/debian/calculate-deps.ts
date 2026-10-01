/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { spawnSync } from 'child_process';
import { constants, statSync } from 'fs';
import { tmpdir } from 'os';
import path from 'path';
import manifests from '../../../cgmanifest.json' with { type: 'json' };
import { additionalDeps } from './dep-lists.ts';
import type { DebianArchString } from './types.ts';

export function generatePackageDeps(files: string[], arch: DebianArchString, chromiumSysroot: string, vscodeSysroot: string): Set<string>[] {
	const dependencies: Set<string>[] = files.map(file => calculatePackageDeps(file, arch, chromiumSysroot, vscodeSysroot));
	const additionalDepsSet = new Set(additionalDeps);
	dependencies.push(additionalDepsSet);
	dependencies.push(calculateSymbolVersionFloors(files));
	return dependencies;
}

// First GCC release whose libstdc++ provides GLIBCXX_3.4.<key>, see
// https://gcc.gnu.org/onlinedocs/libstdc++/manual/abi.html. Older versions are
// already covered by the sysroot symbols files dpkg-shlibdeps reads.
const libstdcxxVersionByGlibcxxMinor: Record<number, string> = {
	21: '5', 22: '6', 23: '7', 24: '7.2', 25: '8', 26: '9', 27: '9.2', 28: '9.3',
	29: '11', 30: '12', 31: '13', 32: '13.2', 33: '14', 34: '15',
};

// dpkg-shlibdeps resolves symbols against the symbols files of the sysroots
// (Debian bullseye, GCC 10), which know no glibc newer than 2.31 and no
// libstdc++ newer than GCC 10. This fork compiles the native modules on the
// build host instead of against the sysroot, so they can need newer GLIBC_ and
// GLIBCXX_ symbol versions than those files know, and dpkg-shlibdeps then
// silently states too low a libc6 and libstdc++6. Read the versions the binaries actually require
// and state the highest of each directly, so apt refuses a distro that cannot
// load them instead of installing an app that fails to start.
function calculateSymbolVersionFloors(files: string[]): Set<string> {
	let glibc: number[] = [];
	let glibcxxMinor = -1;
	for (const file of files) {
		const result = spawnSync('objdump', ['-p', path.resolve(file)]);
		if (result.status !== 0) {
			throw new Error(`objdump failed on ${file} with exit code ${result.status}. stderr:\n${result.stderr}`);
		}
		const output = result.stdout.toString('utf-8');
		const referencesStart = output.indexOf('Version References:');
		if (referencesStart < 0) {
			continue;
		}
		const references = output.substring(referencesStart);
		const glibcVersions = Array.from(references.matchAll(/\bGLIBC_(\d+(?:\.\d+)*)\b/g), match => match[1].split('.').map(Number));
		// Packed relative relocations are only understood from glibc 2.36 on.
		if (references.includes('GLIBC_ABI_DT_RELR')) {
			glibcVersions.push([2, 36]);
		}
		for (const version of glibcVersions) {
			if (compareVersions(version, glibc) > 0) {
				glibc = version;
			}
		}
		for (const match of references.matchAll(/\bGLIBCXX_3\.4\.(\d+)\b/g)) {
			glibcxxMinor = Math.max(glibcxxMinor, Number(match[1]));
		}
	}

	const floors = new Set<string>();
	if (glibc.length) {
		floors.add(`libc6 (>= ${glibc.join('.')})`);
	}
	const libstdcxxVersion = libstdcxxVersionByGlibcxxMinor[glibcxxMinor];
	if (libstdcxxVersion) {
		floors.add(`libstdc++6 (>= ${libstdcxxVersion})`);
	} else if (glibcxxMinor > Math.max(...Object.keys(libstdcxxVersionByGlibcxxMinor).map(Number))) {
		throw new Error(`The binaries need GLIBCXX_3.4.${glibcxxMinor}, which is not in libstdcxxVersionByGlibcxxMinor yet.`);
	}
	return floors;
}

function compareVersions(a: number[], b: number[]): number {
	for (let i = 0; i < Math.max(a.length, b.length); i++) {
		const difference = (a[i] ?? 0) - (b[i] ?? 0);
		if (difference !== 0) {
			return difference;
		}
	}
	return 0;
}

// Based on https://source.chromium.org/chromium/chromium/src/+/main:chrome/installer/linux/debian/calculate_package_deps.py.
function calculatePackageDeps(binaryPath: string, arch: DebianArchString, chromiumSysroot: string, vscodeSysroot: string): Set<string> {
	try {
		if (!(statSync(binaryPath).mode & constants.S_IXUSR)) {
			throw new Error(`Binary ${binaryPath} needs to have an executable bit set.`);
		}
	} catch (e) {
		// The package might not exist. Don't re-throw the error here.
		console.error('Tried to stat ' + binaryPath + ' but failed.');
	}

	// Get the Chromium dpkg-shlibdeps file.
	const chromiumManifest = manifests.registrations.filter(registration => {
		return registration.component.type === 'git' && registration.component.git!.name === 'chromium';
	});
	const dpkgShlibdepsUrl = `https://raw.githubusercontent.com/chromium/chromium/${chromiumManifest[0].version}/third_party/dpkg-shlibdeps/dpkg-shlibdeps.pl`;
	const dpkgShlibdepsScriptLocation = `${tmpdir()}/dpkg-shlibdeps.pl`;
	const result = spawnSync('curl', [dpkgShlibdepsUrl, '-o', dpkgShlibdepsScriptLocation]);
	if (result.status !== 0) {
		throw new Error('Cannot retrieve dpkg-shlibdeps. Stderr:\n' + result.stderr);
	}
	const cmd = [dpkgShlibdepsScriptLocation, '--ignore-weak-undefined', '--ignore-missing-info'];
	switch (arch) {
		case 'amd64':
			cmd.push(`-l${chromiumSysroot}/usr/lib/x86_64-linux-gnu`,
				`-l${chromiumSysroot}/lib/x86_64-linux-gnu`,
				`-l${vscodeSysroot}/usr/lib/x86_64-linux-gnu`,
				`-l${vscodeSysroot}/lib/x86_64-linux-gnu`);
			break;
		case 'armhf':
			cmd.push(`-l${chromiumSysroot}/usr/lib/arm-linux-gnueabihf`,
				`-l${chromiumSysroot}/lib/arm-linux-gnueabihf`,
				`-l${vscodeSysroot}/usr/lib/arm-linux-gnueabihf`,
				`-l${vscodeSysroot}/lib/arm-linux-gnueabihf`);
			break;
		case 'arm64':
			cmd.push(`-l${chromiumSysroot}/usr/lib/aarch64-linux-gnu`,
				`-l${chromiumSysroot}/lib/aarch64-linux-gnu`,
				`-l${vscodeSysroot}/usr/lib/aarch64-linux-gnu`,
				`-l${vscodeSysroot}/lib/aarch64-linux-gnu`);
			break;
	}
	cmd.push(`-l${chromiumSysroot}/usr/lib`);
	cmd.push(`-l${path.dirname(path.resolve(binaryPath))}`);
	cmd.push(`-L${vscodeSysroot}/debian/libxkbfile1/DEBIAN/shlibs`);
	cmd.push('-O', '-e', path.resolve(binaryPath));

	const dpkgShlibdepsResult = spawnSync('perl', cmd, { cwd: chromiumSysroot });
	if (dpkgShlibdepsResult.status !== 0) {
		throw new Error(`dpkg-shlibdeps failed with exit code ${dpkgShlibdepsResult.status}. stderr:\n${dpkgShlibdepsResult.stderr} `);
	}

	const shlibsDependsPrefix = 'shlibs:Depends=';
	const requiresList = dpkgShlibdepsResult.stdout.toString('utf-8').trimEnd().split('\n');
	let depsStr = '';
	for (const line of requiresList) {
		if (line.startsWith(shlibsDependsPrefix)) {
			depsStr = line.substring(shlibsDependsPrefix.length);
		}
	}
	// Refs https://chromium-review.googlesource.com/c/chromium/src/+/3572926
	// Chromium depends on libgcc_s, is from the package libgcc1.  However, in
	// Bullseye, the package was renamed to libgcc-s1.  To avoid adding a dep
	// on the newer package, this hack skips the dep.  This is safe because
	// libgcc-s1 is a dependency of libc6.  This hack can be removed once
	// support for Debian Buster and Ubuntu Bionic are dropped.
	//
	// Remove kerberos native module related dependencies as the versions
	// computed from sysroot will not satisfy the minimum supported distros
	// Refs https://github.com/microsoft/vscode/issues/188881.
	// TODO(deepak1556): remove this workaround in favor of computing the
	// versions from build container for native modules.
	const filteredDeps = depsStr.split(', ').filter(dependency => {
		return !dependency.startsWith('libgcc-s1');
	}).sort();
	const requires = new Set(filteredDeps);
	return requires;
}
