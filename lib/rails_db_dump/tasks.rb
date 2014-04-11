namespace :db do
  desc "Dump the database to standard output. Pass a TABLE_NAME environment variable to dump a single table"
  task :dump, :dump_options do |t, args|
    require 'yaml'
    require 'shellwords'

    config = YAML.load_file(File.join(Rails.root,'config','database.yml'))[Rails.env]
    table_name = ENV['TABLE_NAME']
    dump_options = Shellwords.split(args.dump_options || '')

    case config["adapter"]
    when /^mysql/
      mysql_args = {
        'host'      => '--host',
        'port'      => '--port',
        'socket'    => '--socket',
        'username'  => '--user',
        'encoding'  => '--default-character-set',
        'password'  => '--password'
      }.map { |opt, arg| "#{arg}=#{config[opt]}" if config[opt] }.compact

      mysql_args << config['database']
      mysql_args << table_name unless table_name.blank?
      mysql_args.concat(args.dump_options)

      exec('mysqldump', *mysql_args)

    when "postgresql"
      ENV['PGUSER']     = config["username"] if config["username"]
      ENV['PGHOST']     = config["host"] if config["host"]
      ENV['PGPORT']     = config["port"].to_s if config["port"]
      ENV['PGPASSWORD'] = config["password"].to_s if config["password"]

      postgres_args = [config['database']]

      if table_name.present?
        postgres_args.concat(['-t', table_name])
      end

      postgres_args.concat(dump_options)

      exec('pg_dump', *postgres_args)

    when "sqlite"
      raise 'Table dumping not supported with sqlite... yet' unless table_name.blank?
      exec('sqlite', config["database"], '.dump')

    when "sqlite3"
      raise 'Table dumping not supported with sqlite... yet' unless table_name.blank?
      exec('sqlite3', config['database'], '.dump')

    else
      abort "Don't know how to dump #{config['database']}."
    end
  end

  desc "Restore the database from standard input."
  task :restore do
    # Doesn't get any simpler than that!
    if Rails.version > '3'
      exec 'rails', 'dbconsole', '--include-password'
    else
      exec File.join(Rails.root, 'script', 'dbconsole'), '--include-password'
    end
  end
end
