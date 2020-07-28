class LargeTablePrimaryKeysToBigints < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.ahoy_messages")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE ahoy_messages
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.articles")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE articles
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint,
          ALTER COLUMN second_user_id TYPE bigint,
          ALTER COLUMN third_user_id TYPE bigint,
          ALTER COLUMN organization_id TYPE bigint,
          ALTER COLUMN collection_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.follows")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE follows
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN followable_id TYPE bigint,
          ALTER COLUMN follower_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.identities")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE identities
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.notifications")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE notifications
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN notifiable_id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.reactions")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE reactions
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN reactable_id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.users")
    safety_assured { change_column :users, :id, :bigint }
  end

  def down
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.ahoy_messages")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE ahoy_messages
          ALTER COLUMN id TYPE int,
          ALTER COLUMN user_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.articles")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE articles
          ALTER COLUMN id TYPE int,
          ALTER COLUMN user_id TYPE int,
          ALTER COLUMN second_user_id TYPE int,
          ALTER COLUMN third_user_id TYPE int,
          ALTER COLUMN organization_id TYPE int,
          ALTER COLUMN collection_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.follows")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE follows
          ALTER COLUMN id TYPE int,
          ALTER COLUMN followable_id TYPE int,
          ALTER COLUMN follower_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.identities")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE identities
          ALTER COLUMN id TYPE int,
          ALTER COLUMN user_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.notifications")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE notifications
          ALTER COLUMN id TYPE int,
          ALTER COLUMN notifiable_id TYPE int,
          ALTER COLUMN user_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.reactions")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE reactions
          ALTER COLUMN id TYPE int,
          ALTER COLUMN reactable_id TYPE int,
          ALTER COLUMN user_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.users")
    safety_assured { change_column :users, :id, :int }
  end
end
