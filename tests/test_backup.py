import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT=Path(__file__).resolve().parents[1]/"backup/backup4tb.sh"


class Backup(unittest.TestCase):
    def run_backup(self,apply=False,mounted=True,fail=False,same=False):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); source=root/"source";dest=root/"dest";bin_dir=root/"bin"
            for p in [source,dest,bin_dir]:p.mkdir()
            log=root/"rsync-args"
            (bin_dir/"mountpoint").write_text("#!/bin/sh\nexit "+("0" if mounted else "1")+"\n")
            (bin_dir/"rsync").write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_LOG"\nexit '+("23" if fail else "0")+"\n")
            for p in bin_dir.iterdir():p.chmod(0o755)
            env={**os.environ,"PATH":str(bin_dir)+os.pathsep+os.environ["PATH"],"BACKUP_SOURCE":str(source),"BACKUP_DESTINATION":str(source if same else dest),"TEST_LOG":str(log)}
            result=subprocess.run(["bash",str(SCRIPT),*( ["--apply"] if apply else [])],env=env,capture_output=True,text=True)
            return result,log.read_text() if log.exists() else ""

    def test_preview_is_default(self):
        result,args=self.run_backup()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn("--dry-run",args)

    def test_missing_mount_and_overlap_abort(self):
        for kwargs in [{"mounted":False},{"same":True}]:
            result,args=self.run_backup(**kwargs)
            self.assertNotEqual(result.returncode,0)
            self.assertEqual(args,"")

    def test_apply_propagates_failure(self):
        result,args=self.run_backup(apply=True,fail=True)
        self.assertEqual(result.returncode,23)
        self.assertNotIn("--dry-run",args)
        self.assertNotIn("completed successfully",result.stdout)
