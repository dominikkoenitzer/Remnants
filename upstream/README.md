# Taking a new upstream release

Remnants tracks upstream Code - OSS releases without importing Microsoft's git
history. Each update is a three-way merge of the new upstream tag onto
`main`, with the previous upstream tag as the merge base, followed by the
same removal that produced Remnants in the first place.

## Files

| File | Purpose |
| --- | --- |
| `BASE` | The upstream tag and commit Remnants currently tracks. Update it after a sync lands. |
| `remove-dirs.txt`, `remove-files.txt` | Everything the removal deletes. Directories also cover files upstream adds inside them later. |
| `owned-paths.txt` | Paths Remnants owns outright. The Remnants side always wins there. |
| `sync.sh` | Runs the merge and the removal and writes `sync/<tag>`. Git only. |
| `importgate.py` | Lists files that still import a removed module. Must report 0. |
| `lockmerge.py` | Restores upstream's lockfile entries (and their `libc` fields) after a regeneration. |

## Running a sync

1. Clone this repository into a scratch directory and add the remotes:

   ```sh
   git clone https://github.com/dominikkoenitzer/Remnants.git remnants-sync
   cd remnants-sync
   git remote add upstream https://github.com/microsoft/vscode.git
   git remote rename origin remnants
   ```

   Set the commit identity you publish under (`git config user.name`,
   `git config user.email`) before running anything.

2. Run the sync for the new tag:

   ```sh
   upstream/sync.sh 1.140.0
   ```

   The report in `upstream/report-1.140.0/` lists the conflicts, the files that
   still contain conflict markers, the files that import removed modules, and
   the new upstream files kept in the tree.

3. Work on a branch created from `sync/<tag>` and resolve, one small commit per
   area:
   - conflicted lockfiles were already taken from upstream;
   - where Remnants deleted a file upstream edited, keep the deletion;
   - for branding, product and theme files, keep the Remnants values and add
     upstream's new non-AI keys;
   - in shared code, keep upstream's non-AI changes and drop AI registrations.

4. Triage `new-files.txt`. Remove new AI modules together with their
   registrations and add them to the path lists, so the next sync drops them
   automatically. Keep shared plumbing Remnants deliberately retains (see
   `CHANGES.md`).

5. Repeat until both gates are clean:

   ```sh
   python upstream/importgate.py HEAD /tmp/importgate.txt
   git grep -n -E '^(<<<<<<<|>>>>>>>)( |$)'
   ```

6. Regenerate each lockfile whose `package.json` changed, one directory at a
   time, then reconcile it with upstream's copy:

   ```sh
   (cd remote && npm install --package-lock-only --ignore-scripts)
   python upstream/lockmerge.py 1.140.0 remote/package-lock.json
   ```

   Update any `allowScripts` pins in `package.json` to the resolved versions.

7. Open a pull request and let CI type-check and build it. Once it lands, set
   `BASE` to the new tag and its commit, and record the update in `CHANGES.md`.
