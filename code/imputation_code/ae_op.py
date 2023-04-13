import random
import pandas as pd
import numpy as np
from keras.utils import np_utils
from keras.models import Sequential
from keras.layers.core import Dropout, Dense
import keras as k
import keras.backend as K
from scipy.stats import zscore

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
    
  def make_reconstruction_loss(n_features):
      def reconstruction_loss(input_and_mask, y_pred):
          
            X_values = input_and_mask[:, :n_features]
            
            missing_mask = input_and_mask[:, n_features:]
            
            observed_mask = 1 - missing_mask
            
            X_values_observed = X_values * observed_mask
            
            pred_observed = y_pred * observed_mask
            
            squared_diff = K.square(pred_observed - X_values_observed)
            mse = K.sum(squared_diff, axis=-1)/K.sum(observed_mask, axis=-1)
  
            return mse
      return reconstruction_loss
    
  K.clear_session()
  
  column_names = list(x.columns.values)
  labels = x['group']
  X = x.iloc[:, 0:len(x.columns)-1]
  X = np.array(X.T)
  n_dims = X.shape[1]
  input = k.Input(shape=(2 * n_dims,))
  encoded = k.layers.Dense(128)(input)
  encoded = k.layers.Dropout(0.2)(encoded)
  encoded = k.layers.Dense(32)(encoded)
  encoded = k.layers.Dropout(0.2)(encoded)
  encoded = k.layers.Dense(8)(encoded)
  decoded = k.layers.Dense(32)(encoded)
  decoded = k.layers.Dense(128)(decoded)
  decoded = k.layers.Dense(n_dims)(decoded)

  encoder = k.Model(input, encoded)
  autoencoder = k.Model(input, decoded)
  
  loss_function = make_reconstruction_loss(n_dims)
  autoencoder.compile(optimizer="adam", loss=loss_function)
  mask = np.array(bool_to_binary(create_missing_mask(X)))
  X_no_na = replace_nan(X, replacement = 1)
  input_with_mask = np.hstack([X_no_na, mask])

  autoencoder.fit(x=input_with_mask, y=input_with_mask, epochs=100, batch_size=32)
  imputed = autoencoder.predict(input_with_mask)
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
  
mcar_10i.to_csv('../../data/MCAR/mcar10/aeop_mcar_10.csv')
mcar_25i.to_csv('../../data/MCAR/mcar25/aeop_mcar_25.csv')
mcar_40i.to_csv('../../data/MCAR/mcar40/aeop_mcar_40.csv')
mnar_30i.to_csv('../../data/MNAR/mnar30/aeop_mnar_30.csv')
mnar_50i.to_csv('../../data/MNAR/mnar50/aeop_mnar_50.csv')
mcar_pathi.to_csv('../../data/path/mcar_40/aeop_path_mcar.csv')
mnar_pathi.to_csv('../../data/path/mnar_50/aeop_path_mnar.csv')
