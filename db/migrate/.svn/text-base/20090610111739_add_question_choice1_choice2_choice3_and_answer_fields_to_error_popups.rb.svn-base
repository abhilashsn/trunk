class AddQuestionChoice1Choice2Choice3AndAnswerFieldsToErrorPopups < ActiveRecord::Migration
  def up
     add_column :error_popups, :Question,  :string
     add_column :error_popups, :choice1,  :string
     add_column :error_popups, :choice2,  :string
     add_column :error_popups, :choice3,  :string
     add_column :error_popups, :answer,  :string
  end

  def down
     remove_column :error_popups, :Question
     remove_column :error_popups, :choice1
     remove_column :error_popups, :choice2
     remove_column :error_popups, :choice3
     remove_column :error_popups, :answer
  end
end
