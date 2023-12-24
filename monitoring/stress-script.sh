#!/bin/bash

target="https://khalil-wp.20.199.32.73.nip.io"

num_iterations=2


for ((i = 1; i <= num_iterations; i++)); do
  response=$(curl --insecure -s "$target")  
  echo "Request $i - Response: $response" >> ./script_results.txt
  sleep 1  
done
