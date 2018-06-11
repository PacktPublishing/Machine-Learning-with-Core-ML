## CNN for Sketch Classification

### FloydHub
**Getting started with Jupyter notebooks**
https://docs.floydhub.com/getstarted/get_started_jupyter/

*floyd init cnn-sketch-classifier*

**Creating and uploading data**
https://docs.floydhub.com/guides/create_and_upload_dataset/
*floyd data init sketches*
*floyd data upload*

#### Running FloydHub
*floyd run --env keras --data joshnewnham/datasets/sketches/2:sketches_training_data --gpu --mode jupyter*

#### Stop running Job on FloydHub
*floyd stop joshnewnham/projects/cnn-sketch-classifier/2*
