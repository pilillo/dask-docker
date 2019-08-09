repo=datamillcloud
n=dask-gpu
t=$repo/$n
version=0.1

docker build -t $t:$version -f Dockerfile .
