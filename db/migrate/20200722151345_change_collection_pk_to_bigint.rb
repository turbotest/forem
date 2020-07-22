class ChangeCollectionPkToBigint < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      change_column :collections, :id, :bigint
      change_column :articles, :collection_id, :bigint
    }
  end

  def down
    safety_assured {
      change_column :collections, :id, :int
      change_column :articles, :collection_id, :int
    }
  end
end
