#!/bin/bash
# Generate a large markdown file (~6MB)
echo "# Large File Test" > large_test.md
for i in {1..100000}; do
  echo "This is line $i of the large markdown file to test performance truncation. **Bold text** and *italic text*." >> large_test.md
done
echo "DONE"
