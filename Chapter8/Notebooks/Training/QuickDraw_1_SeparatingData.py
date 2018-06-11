from __future__ import print_function
import matplotlib.pyplot as plt
import numpy as np
import random
import csv
import json
from scipy.misc import imresize
import os

CLASS_FILE = '/Users/Joshua.Newnham/Documents/Data/quickdraw_dataset/sketch_classes.csv'
SOURCE_DIR = '/Users/Joshua.Newnham/Documents/Data/quickdraw_dataset/full/simplified/'
DEST_DIR = '/Users/Joshua.Newnham/Documents/Data/quickdraw_dataset/sketchrnn_training_data/'
STAGING_DIR = '/Users/Joshua.Newnham/Documents/Data/quickdraw_dataset/staging/'

def parse_line(ndjson_line):
    """
    Method taken from: 
    https://www.tensorflow.org/versions/master/tutorials/recurrent_quickdraw
    """
    
    # convert string to a JSON object 
    sample = json.loads(ndjson_line)
    label = sample['word']
    strokes = sample['drawing']
    stroke_lengths = [len(stroke[0]) for stroke in strokes]
    total_points = sum(stroke_lengths)
    np_strokes = np.zeros((total_points, 3), dtype=np.float32)
    current_t = 0 
    for stroke in strokes:
        for i in [0,1]:
            np_strokes[current_t:(current_t + len(stroke[0])), i] = stroke[i]
        current_t += len(stroke[0])
        np_strokes[current_t - 1, 2] = 1 # stroke end
        
    # preprocessing 
    # 1. size normalisation 
    lower_point = np.min(np_strokes[:, 0:2], axis=0)
    upper_point = np.max(np_strokes[:, 0:2], axis=0)
    scale = upper_point - lower_point
    scale[scale == 0] = 1 
    np_strokes[:, 0:2] = (np_strokes[:, 0:2] - lower_point) / scale    
    # 2. compute deltas 
    np_strokes = np.hstack((
        np_strokes[1:, 0:2] - np_strokes[0:-1, 0:2], 
        np_strokes[1:,2].reshape(np_strokes.shape[0]-1, 1)))
    
    return np_strokes, label

def load_and_preprocess_data(class_filter_file, source_dir, dest_dir, 
                             num_training_samples=10000, num_validation_samples=1000, 
                             parts=1, # how many files to distribute the data across 
                             show_progress_bar=True):        

    # load classes     
    label_filters = []

    with open(class_filter_file, 'r') as f:
        csv_reader = csv.reader(f)
        for row in csv_reader:
            label_filters.append(row[1])

    # find matching files 
    matching_files = [] 

    for filename in sorted(os.listdir(source_dir)):
        full_filepath = os.path.join(source_dir, filename).lower()
        if os.path.isfile(full_filepath) and ".ndjson" in full_filepath.lower():
            for label_filter in label_filters:
                if label_filter in full_filepath:
                    matching_files.append((label_filter, filename))
                    break 
                    
    print("Found {} matches".format(len(matching_files)))
    
    label2idx = {label[0]:idx for idx, label in enumerate(matching_files)}        
    
    training_stroke_lengths = []
    validation_stroke_lengths = []        
    
    part_num_training_samples = int(num_training_samples / parts)
    part_num_validation_samples = int(num_validation_samples / parts)
    
    print("Breaking data into {} parts; each with {} training samples and {} validation samples".format(
        parts, part_num_training_samples, part_num_validation_samples))
    
    progress_counter = 0
    progress_count = len(matching_files) * parts                  
    
    for part_num in range(parts):                
        training_x = []
        validation_x = []
    
        training_y = np.zeros((0,len(matching_files)), dtype=np.int16)
        validation_y = np.zeros((0,len(matching_files)), dtype=np.int16)
        
        line_number = int(part_num * (part_num_training_samples + part_num_validation_samples))
        
        print("Processing part {} of {} - current line number {}".format(
            part_num, parts, line_number))
    
        for matching_file in matching_files:            
            progress_counter += 1
            if show_progress_bar:
                print("Progress {}".format(int((float(progress_counter)/float(progress_count)) * 100)))
            
            matching_label = matching_file[0]
            matching_filename = matching_file[1]
            
            with open(os.path.join(source_dir, matching_filename), 'r') as f:
                for _ in range(line_number):
                    f.readline()                
            
                for i in range(part_num_training_samples):
                    line = f.readline() 
                    strokes, label = parse_line(line)
                    training_stroke_lengths.append(len(strokes))
                
                    training_x.append(strokes)
                
                    y = np.zeros(len(matching_files), dtype=np.int16)
                    y[label2idx[matching_label]] = 1                                                                                     
                    training_y = np.vstack((training_y, y))
                
                for i in range(part_num_validation_samples):
                    line = f.readline() 
                    strokes, label = parse_line(line)
                
                    validation_stroke_lengths.append(len(strokes))
                    
                    validation_x.append(strokes)
                
                    y = np.zeros(len(matching_files), dtype=np.int16)
                    y[label2idx[matching_label]] = 1
                    validation_y = np.vstack((validation_y, y))
                        
        training_x = np.array(training_x) 
        validation_x = np.array(validation_x)        
    
        # save .npy            
        np.save(os.path.join(dest_dir, "train_{}_x.npy".format(part_num)), training_x)
        np.save(os.path.join(dest_dir, "train_{}_y.npy".format(part_num)), training_y)
        
        np.save(os.path.join(dest_dir, "validation_{}_x.npy".format(part_num)), validation_x)
        np.save(os.path.join(dest_dir, "validation_{}_y.npy".format(part_num)), validation_y)
    
    training_stroke_lengths = np.array(training_stroke_lengths)
    validation_stroke_lengths = np.array(validation_stroke_lengths)
    
    np.save(os.path.join(dest_dir, "train_stroke_lengths.npy"), training_stroke_lengths)
    np.save(os.path.join(dest_dir, "validation_stroke_lengths.npy"), validation_stroke_lengths)          
        
    print("Finished")
    
    print("Training stroke lens: Mean {}, Min {}, Max {}".format(
        np.mean(training_stroke_lengths), 
        np.min(training_stroke_lengths), 
        np.max(training_stroke_lengths)))
    
    print("Validation stroke lens: Mean {}, Min {}, Max {}".format(
        np.mean(validation_stroke_lengths), 
        np.min(validation_stroke_lengths), 
        np.max(validation_stroke_lengths)))        
                
if __name__ == "__main__":
    load_and_preprocess_data(class_filter_file=CLASS_FILE, 
                         source_dir=SOURCE_DIR, 
                         num_training_samples=10000, 
                         num_validation_samples=1000, 
                         dest_dir=DEST_DIR)