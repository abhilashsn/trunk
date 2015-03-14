# Sequence provides access to a two column table of names and sequence values. It uses the method
# # described here:
# http://answers.oreilly.com/topic/172-how-to-use-sequence-generators-as-counters-in-mysql/
# to generate reliable, efficient sequences.
class Sequence < ActiveRecord::Base
  # Returns the next sequence value for a given sequence name.
  # Input: sequence_name the sequence to get
  # Output: the next sequence value

  def self.get_next(sequence_name)
    ActiveRecord::Base.connection.execute("insert into sequences(name, value) values ('#{sequence_name}', last_insert_id(1)) ON DUPLICATE KEY UPDATE value = LAST_INSERT_ID(value + 1)")
    client = ActiveRecord::Base.connection.instance_variable_get("@connection")
    client.last_id
  end
end
