import warnings

with warnings.catch_warnings():
    warnings.filterwarnings("ignore", message="numpy.dtype size changed")
    warnings.filterwarnings("ignore", message="numpy.ufunc size changed")
    warnings.filterwarnings("ignore", category=FutureWarning)
    
    import keras 

import importlib

import matplotlib
import matplotlib.pyplot as plt

from scipy.optimize import fmin_l_bfgs_b
from scipy.misc import imsave
import numpy as np
from PIL import Image # used to load images
import glob 

"""

"""

import tensorflow as tf

from keras.applications.vgg16 import VGG16
from keras.applications.vgg16 import preprocess_input, decode_predictions
from keras import backend as K

TARGET_SIZE = (320,320)

def load_resize_image(img_path, target_size=TARGET_SIZE, preprocess_required=False):
    """
    Load and resize (to target_size) a given image; resizes constraining to the original aspect ratio and 
    crops overflow 
    :param img_path: image path to load and resize 
    :param target_size: resize size 
    :param preprocess_required: Toggles whether resizing will be performed or not 
    
    :return: resized image 
    """
    # Load image 
    img = Image.open(img_path)
    if img.mode is not "RGB":
        img = img.convert('RGB')
    
    if preprocess_required:
        # Get dimensions
        img_width, img_height = img.size
        half_img_width, half_img_height = img_width/2.0, img_height/2.0

        # Crop
        target_width = min(img_width, img_height)
        target_height = min(img_width, img_height)

        left = half_img_width - target_width/2
        top = half_img_height - target_height/2
        right = half_img_width + target_width/2
        bottom = half_img_height + target_height/2

        img = img.crop((left, top, right, bottom))

        # Resize 
        img = img.resize(target_size)
    
    return img 

# Preprocess methods 

rn_mean = np.array([123.68, 116.779, 103.939], dtype=np.float32)

def preproc(x):     
    return (x-rn_mean)[:, :, :, ::-1]

def deproc(x, shape):
    return np.clip(x.reshape(shape)[:, :, :, ::-1] + rn_mean, 0, 255)

class ReflectionPadding2D(keras.layers.Layer):
    """
    Custom layer 
    """
    def __init__(self, padding=(1, 1), **kwargs):
        self.padding = tuple(padding)        
        self.input_spec = [keras.layers.InputSpec(ndim=4)]
        super(ReflectionPadding2D, self).__init__(**kwargs)
        
    def compute_output_shape(self, s):
        return (s[0], s[1] + 2 * self.padding[0], s[2] + 2 * self.padding[1], s[3])

    def call(self, x, mask=None):
        w_pad,h_pad = self.padding
        return tf.pad(x, [[0,0], [h_pad,h_pad], [w_pad,w_pad], [0,0] ], 'REFLECT')
    
    def get_config(self):
        return super(ReflectionPadding2D, self).get_config()
    
def build_model(style_imgpath):
    """
    Creates and returns the FNST Model
    :return: model 
    """
    
    # load style image 
    style = load_resize_image(style_imgpath, preprocess_required=True)
    
    def conv_block(x, filters, size, stride=(2,2), mode='same', act=True):
        x = keras.layers.Conv2D(filters, kernel_size=(size, size), strides=stride, padding=mode)(x)
        x = keras.layers.BatchNormalization()(x)
        return keras.layers.Activation('relu')(x) if act else x
    
    def up_block(x, filters, size):
        x = keras.layers.UpSampling2D()(x)
        x = keras.layers.Conv2D(filters, kernel_size=(size, size), padding='same')(x)
        x = keras.layers.BatchNormalization()(x)
        return keras.layers.Activation('relu')(x)
    
    def res_crop(x):
        return x[:, 2:-2, 2:-2]

    def res_crop_block(ip, nf=64, block_idx=0):
        x = conv_block(ip, nf, 3, (1,1), 'valid')
        x = conv_block(x,  nf, 3, (1,1), 'valid', False)
        ip = keras.layers.Lambda(res_crop, name='res_crop_{}'.format(block_idx))(ip)
        return keras.layers.add([x, ip])    
    
    def rescale_output(x):
        return (x+1)*127.5

    shp = (320, 320, 3)
    inp=keras.layers.Input(shp)

    #x=ReflectionPadding2D((40, 40))(inp)
    x = keras.layers.ZeroPadding2D(padding=(40, 40))(inp)

    x=conv_block(x, 64, 9, (1,1))
    x=conv_block(x, 64, 3)
    x=conv_block(x, 64, 3)
    for i in range(5): x=res_crop_block(x, 64, i)
    x=up_block(x, 64, 3)
    x=up_block(x, 64, 3)
    x=keras.layers.Conv2D(3, kernel_size=(9, 9), activation='tanh', padding='same')(x)
    outp=keras.layers.Lambda(rescale_output, name='rescale_output')(x)
    
    vgg_inp=keras.layers.Input(shp)
    vgg = VGG16(include_top=False, input_tensor=keras.layers.Lambda(preproc)(vgg_inp))
    for l in vgg.layers: 
        l.trainable=False
        
    def get_outp(m, ln): 
        return m.get_layer("block{}_conv2".format(ln)).output    
    
    vgg_content = keras.models.Model(vgg_inp, [get_outp(vgg, o) for o in [2,3,4,5]])
    
    style_targs = [K.variable(o) for o in vgg_content.predict(np.expand_dims(style,0))]
    
    vgg1 = vgg_content(vgg_inp)
    vgg2 = vgg_content(outp)
    
    def mean_sqr_b(diff): 
        dims = list(range(1,K.ndim(diff)))
        return K.expand_dims(K.sqrt(K.mean(diff**2, dims)), 0)
    
    def gram_matrix_b(x):
        x = K.permute_dimensions(x, (0, 3, 1, 2))
        s = K.shape(x)
        feat = K.reshape(x, (s[0], s[1], s[2]*s[3]))
        return K.batch_dot(feat, K.permute_dimensions(feat, (0, 2, 1))) / K.prod(K.cast(s[1:], K.floatx()))
    
    w=[0.1, 0.2, 0.6, 0.1]

    def tot_loss(x):
        loss = 0 
        n = len(style_targs)
        for i in range(n):
            loss += mean_sqr_b(gram_matrix_b(x[i+n]) - gram_matrix_b(style_targs[i])) / 2.
            loss += mean_sqr_b(x[i]-x[i+n]) * w[i]
        return loss
    
    loss = keras.layers.Lambda(tot_loss)(vgg1+vgg2)
    m_style = keras.models.Model([inp, vgg_inp], loss)
    
    m_style.compile('adam', 'mae')    
    K.set_value(m_style.optimizer.lr, 1e-4)
    
    model = keras.models.Model(inp, outp)
    
    return model 