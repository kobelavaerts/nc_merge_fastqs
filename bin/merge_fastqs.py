#!/usr/bin/env python3
import gzip
import sys

i1_path = sys.argv[1]      # e.g. I1.fastq.gz
umi_path = sys.argv[2]     # e.g. UMI.fastq.gz
out_path = sys.argv[3]     # e.g. I1_32bp.fastq.gz

def open_maybe_gzip(path, mode='rt'):
    return gzip.open(path, mode) if path.endswith('.gz') else open(path, mode)
    # return gzip.open(path, mode)
with open_maybe_gzip(i1_path, 'rt') as f_i1, \
     open_maybe_gzip(umi_path, 'rt') as f_umi, \
     gzip.open(out_path, 'wt') as out:

    while True:
        # Read 4-line FASTQ block from each file
        i1_id  = f_i1.readline()
        umi_id = f_umi.readline()
        if not i1_id or not umi_id:
            break  # end of file

        i1_seq = f_i1.readline().rstrip()
        umi_seq = f_umi.readline().rstrip()
        i1_plus = f_i1.readline()
        umi_plus = f_umi.readline()
        i1_qual = f_i1.readline().rstrip()
        umi_qual = f_umi.readline().rstrip()

        # Optional: sanity check read IDs (before first space)
        if i1_id.split()[0] != umi_id.split()[0]:
            raise RuntimeError(f"Read ID mismatch:\n{i1_id}{umi_id}")

        # Concatenate sequence and qualities
        new_seq = i1_seq + umi_seq
        new_qual = i1_qual + umi_qual

        # Write new FASTQ (use I1 header)
        out.write(i1_id)
        out.write(new_seq + "\n")
        out.write(i1_plus)
        out.write(new_qual + "\n")
