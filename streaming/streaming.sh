cd /opt/spark/bin

echo "./spark-submit $(python3 /submit_args.py) /streaming.py" 
./spark-submit $(python3 /submit_args.py) /streaming.py 