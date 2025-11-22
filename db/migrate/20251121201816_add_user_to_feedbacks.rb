class AddUserToFeedbacks < ActiveRecord::Migration[7.1]
  def change
    # Primero agregamos la columna permitiendo null
    add_reference :feedbacks, :user, null: true, foreign_key: true
    
    # Si hay feedbacks existentes, necesitaremos manejarlos
    # En este caso, simplemente permitiremos null ya que son feedbacks anónimos
  end
end
