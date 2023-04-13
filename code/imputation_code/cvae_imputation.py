import random
import pandas as pd
import numpy as np
from keras.utils import np_utils
from keras.models import Sequential
from keras.layers.core import Dropout, Dense
import keras as k
import keras
import keras.backend as K

mcar_10 = pd.read_csv('../../data/MCAR/mcar10/mcar_10.csv', index_col = 0)
mcar_25 = pd.read_csv('../../data/MCAR/mcar25/mcar_25.csv', index_col = 0)
mcar_40 = pd.read_csv('../../data/MCAR/mcar40/mcar_40.csv', index_col = 0)
mnar_30 = pd.read_csv('../../data/MNAR/mnar30/mnar_30.csv', index_col = 0)
mnar_50 = pd.read_csv('../../data/MNAR/mnar50/mnar_50.csv', index_col = 0)
mcar_path = pd.read_csv('../../data/path/mcar_40/path_mcar_40.csv', index_col = 0)
mnar_path = pd.read_csv('../../data/path/mnar_50/path_mnar_50.csv', index_col = 0)


def na_autoencoder(x):
  
  def masked_mae(X_true, X_pred, mask):
    masked_diff = X_true[mask] - X_pred[mask]
    return np.mean(np.abs(masked_diff))


  def fill(self, missing_mask):
      self.data[missing_mask] = -1
  
  
  def create_missing_mask(X):
      if X.dtype != "f" and X.dtype != "d":
          X = X.astype(float)
      return np.isnan(X.data)
  
  
  def bool_to_binary(matrix):
      """
      Converts a boolean matrix to a binary matrix
      
      :param matrix: a boolean matrix
      :return: a binary matrix
      """
      binary_matrix = []
      for row in matrix:
          binary_row = []
          for value in row:
              binary_row.append(1 if value else 0)
          binary_matrix.append(binary_row)
      return binary_matrix
  
  
  def replace_nan(data, replacement):
      """
      Replace NaN values in a given array with a specific number.
  
      Args:
      data (array): The data to be processed.
      replacement (float or int): The number to replace NaN values with.
  
      Returns:
      The processed data with NaN values replaced by the specified number.
      """
  
      if not isinstance(data, np.ndarray):
          raise ValueError("Unsupported data type. Function supports numpy arrays only.")
  
      data[np.isnan(data)] = replacement
      
      return data
    
  def reconstruction(input_and_mask, y_pred):
      X_values = input_and_mask[:, :n_dims]
  
      missing_mask = input_and_mask[:, n_dims:]
  
      observed_mask = 1 - missing_mask
  
      X_values_observed = X_values * observed_mask
  
      pred_observed = y_pred * observed_mask
  
      mse = K.sum(K.square(pred_observed - X_values_observed) * K.cast(K.not_equal(X_values_observed, 0), K.floatx())) / K.maximum(K.sum(K.cast(K.not_equal(X_values_observed, 0), K.floatx())), 1)
      #mse = K.mean(K.square(X_values_observed * K.cast(K.not_equal(X_values_observed, 0), K.floatx()) - pred_observed), axis=-1)
  
  
      return mse
    
  def sampling(args):
      # reparameterization trick
      # instead of sampling from Q(z|x), sample eps = N(0,I)
      # then x = x_mean + x_sigma*eps= x_mean + sqrt(e^(x_log_var))*eps = x_mean + e^(0.5 * x_log_var)*eps
      x_mean, x_log_var = args
      epsilon = K.random_normal(shape=(K.shape(x_mean)[0], latent_dim), mean=0.,
                                stddev=1.0)
      return x_mean + K.exp(0.5 * x_log_var) * epsilon
    
  K.clear_session()
  
  column_names = list(x.columns.values)
  labels = x['group']
  X = x.iloc[:, 0:len(x.columns)-1]
  X = X.T
  means = X.mean(axis = 1)
  means2 = [0 if x < means.mean() else 1 for x in means]
  X = np.array(X)
  


  n_dims = X.shape[1]
  original_dim = n_dims
  latent_dim = 2
  
  # Variational autoencoder model
  input_img = keras.layers.Input(shape=(original_dim*2,))
  condition = keras.layers.Input(shape = (1,))
  conditional = keras.layers.Concatenate()([input_img, condition])
  encoded = keras.layers.Dense(64)(conditional)
  encoded = keras.layers.Dense(16)(encoded)
  x_mean = keras.layers.Dense(latent_dim)(encoded)
  x_log_var = keras.layers.Dense(latent_dim)(encoded) # implementation choice to encode the log variance i.s.o. the standard deviation
  
  x = keras.layers.Lambda(sampling, output_shape=(latent_dim,))([x_mean, x_log_var])
  x = keras.layers.Concatenate()([x,condition])
  # at this point the representation has dimension: latent_dim 
  
  decoded = keras.layers.Dense(16)(x)
  decoded = keras.layers.Dense(64)(decoded)
  decoded = keras.layers.Dense(original_dim, activation='linear')(decoded)
  vae = keras.Model([input_img,condition], decoded, name='vae')
  
  # Create the loss function and compile the model
  # The loss function as defined by paper Kingma
  
  reconstruction_loss = original_dim * reconstruction(input_img, decoded)  
  kl_loss =  -0.5 * K.sum(1 + x_log_var - K.square(x_mean) -K.exp(x_log_var), axis=-1)
  vae_loss = K.mean(reconstruction_loss + kl_loss)
  vae.add_loss(vae_loss)
  vae.compile(optimizer='adam')
  
  # Next the encoder part and decoder model, in order to inspect the inner representation, referencing the autoencode layers (the 3 models share there weights)
  # This part can be ommitted in case you don't want to use the inner latent representation 
  
  # encoder model (first part of the variotional autoencoder) 
  encoder = keras.Model([input_img,condition], [x_mean, x_log_var, x], name='encoder')
  #print (encoder.summary())
  

  mask = np.array(bool_to_binary(create_missing_mask(X)))
  X_no_na = replace_nan(X, replacement = 1)
  input_with_mask = np.hstack([X_no_na, mask])

  vae.fit([input_with_mask,means],input_with_mask,
          shuffle=True,
          epochs=1000,
          batch_size=32,
          #validation_split= 0.2,
          #callbacks=[early_stop]
         )
       
  imputed = vae.predict([input_with_mask,means])
  imputed_df = pd.DataFrame(imputed)
  imputed_df = imputed_df.T
  imputed_df['group'] = labels.values
  imputed_df.columns = column_names
  return imputed_df

  
mcar_10i = na_autoencoder(mcar_10)
mcar_25i = na_autoencoder(mcar_25)
mcar_40i = na_autoencoder(mcar_40)
mnar_30i = na_autoencoder(mnar_30)
mnar_50i = na_autoencoder(mnar_50)
mcar_pathi = na_autoencoder(mcar_path)
mnar_pathi = na_autoencoder(mnar_path)   
  
mcar_10i.to_csv('../../data/MCAR/mcar10/cvae_mcar_10.csv')
mcar_25i.to_csv('../../data/MCAR/mcar25/cvae_mcar_25.csv')
mcar_40i.to_csv('../../data/MCAR/mcar40/cvae_mcar_40.csv')
mnar_30i.to_csv('../../data/MNAR/mnar30/cvae_mnar_30.csv')
mnar_50i.to_csv('../../data/MNAR/mnar50/cvae_mnar_50.csv')
mcar_pathi.to_csv('../../data/path/mcar_40/cvae_path_mcar.csv')
mnar_pathi.to_csv('../../data/path/mnar_50/cvae_path_mnar.csv')
