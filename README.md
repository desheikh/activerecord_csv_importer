# ActiveRecordCSVImporter

[![Ruby](https://github.com/desheikh/activerecord_csv_importer/actions/workflows/ruby.yml/badge.svg)](https://github.com/desheikh/activerecord_csv_importer/actions/workflows/ruby.yml)

ActiveRecordCSVImporter is a modified version CSVImporter, which uses activerecord-import to speed up processing.

The key difference with CSVImporter is the removal of callback support, since that is incompatible with bulk inserts. Additional config options are available instead to deal with batching and index conflicts.

It is compatible with ActiveRecord and any Databases supported by activerecord-import.

## Usage tldr;

Define your CSVImporter:

```ruby
class ImportUserCSV
  include ActiveRecordCSVImporter

  model User # an active record like model

  column :email, to: ->(email) { email.downcase }, required: true
  column :first_name, as: [ /first.?name/i, /pr(é|e)nom/i ]
  column :last_name,  as: [ /last.?name/i, "nom" ]

  on_duplicate_key(
    on_duplicate_key_update: {
      conflict_target: [:email], columns: [:first_name, :last_name]
    }
  )

  batch_size 500

  each_batch { |report|
    puts report.total_count
    puts report.completed_count
    puts report.failed_rows
  }
end
```

Run the import:

```ruby
import = ImportUserCSV.new(file: my_file)

import.valid_header?  # => false
import.report.message # => "The following columns are required: email"

# Assuming the header was valid, let's run the import!

import.run!
import.report.sucess? # => true
import.report.message  # => "Import completed. 4 created, 2 updated, 1 failed to update"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord_csv_importer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem activerecord_csv_importer

## Usage

### Create an Importer

Create a class and include `CSVImporter`.

```ruby
class ImportUserCSV
  include CSVImporter
end
```

### Associate an active record model

The `model` is can be a active record model.

```ruby
class ImportUserCSV
  include CSVImporter

  model User
end
```

It can also be a relation which is handy to preset attributes:

```ruby
class User
  scope :pending, -> { where(status: 'pending') }
end

class ImportUserCSV
  include CSVImporter

  model User.pending
end
```

You can change the configuration at runtime to scope down to associated
records.

```ruby
class Team
  has_many :users
end

team = Team.find(1)

ImportUserCSV.new(path: "tmp/my_file.csv") do
  model team.users
end
```


### Define columns and their mapping

This is where the fun begins.

```ruby
class ImportUserCSV
  include CSVImporter

  model User

  column :email
end
```

This will map the column named email to the email attribute. By default,
we downcase and strip the columns so it will work with a column spelled " EMail ".

Now, email could also be spelled "e-mail", or "mail", or even "courriel"
(oh, canada). Let's give it a couple of aliases then:


```ruby
  column :email, as: [/e.?mail/i, "courriel"]
```

Nice, emails should be downcased though, so let's do this.

```ruby
  column :email, as: [/e.?mail/i, "courriel"], to: ->(email) { email.downcase }
```

Now, what if the user does not provide the email column? It's not worth
running the import, we should just reject the CSV file right away.
That's easy:

```ruby
class ImportUserCSV
  include CSVImporter

  model User

  column :email, required: true
end

import = ImportUserCSV.new(content: "name\nbob")
import.valid_header? # => false
import.report.status # => :invalid_header
import.report.message # => "The following columns are required: 'email'"
```


### Upsert

You usually want to prevent duplicates when importing a CSV file. activerecord-import provides ON CONFLICT support for MySQL, SQLite (IGNORE only), and PostgreSQL. See the activerecord-import wiki for detailed syntax.

NOTE: If you have set up a unique index on a field and not set an appropriate ON CONFLICT resolution, activerecord_csv_import will raise an exception on the first duplicate insert.

```ruby
class ImportUserCSV
  include CSVImporter

  model User

  column :email, to: ->(email) { email.downcase }
  column :first_name
  column :last_name

  on_duplicate_key(
    on_duplicate_key_update: {
      conflict_target: [:email], columns: [:first_name, :last_name]
    }
  )
end
```

You are now done defining your importer, let's run it!

### Import from a file, path or string

You can import from a file, path or just the CSV content. Please note
that we currently load the entire file in memory. Feel free to
contribute if you need to support CSV files with millions of lines! :)

```ruby
import = ImportUserCSV.new(file: my_file)
import = ImportUserCSV.new(path: "tmp/new_users.csv")
import = ImportUserCSV.new(content: "email,name\nbob@example.com,bob")
```

### Overwrite configuration at runtime

It is often needed to change the configuration at runtime, that's quite
easy:

```ruby
team = Team.find(1)
import = ImportUserCSV.new(file: my_file) do
  model team.users
end
```

### `each_batch` callback

The number of rows to insert in the bulk query can be set by setting `batch_size` (default 500)

The each batch callback is triggered after each batch is processed and returns the report object for the full process. This is generally useful when you want to display progress.

```ruby
progress_bar = ProgressBar.new

UserImport.new(file: my_file) do
  each_batch do |report|
    progress_bar.increment(report.progress_percentage)
  end
end
```
Other available methods are:
- total_count
- completed_count
- failed_rows

### Validate the header

On a web application, as soon as a CSV file is uploaded, you can check
if it has the required columns. This is handy to fail early an provide
the user with a meaningful error message right away.

```ruby
import = ImportUserCSV.new(file: params[:csv_file])
import.valid_header? # => false
import.report.message # => "The following columns are required: "email""
```

### Run the import and provide feedback to the user

```ruby
import = ImportUserCSV.new(file: params[:csv_file])
import.run!
import.report.message  # => "Import completed."
```

You can get your hands dirty and fetch the errored rows and the
associated error message:

```ruby
import.report.invalid_rows.map { |row| [row.model.email, row.errors] }
  # => [ ['INVALID_EMAIL', 'first_name', 'last_name', { 'email' => 'is not an email' }] ]
```

We do our best to map the errors back to the original column name. So
with the following definition:

```ruby
  column :email, as: /e.?mail/i
```

and csv:

```csv
E-Mail,name
INVALID_EMAIL,bob
```

The error returned should be: `{ "E-Mail" => "is invalid" }`

### Custom quote char

You can handle exotic quote chars with the `quote_char` option.

```csv
email,name
bob@example.com,'bob "elvis" wilson'
```

```ruby
import = ImportUserCSV.new(content: csv_content)
import.run!
import.report.status
  # => :invalid_csv_file
import.report.messages
  # => CSV::MalformedCSVError: Illegal quoting in line 2.
```

Let's provide a valid quote char:

```ruby
import = ImportUserCSV.new(content: csv_content, quote_char: "'")
import.run!
  # => [ ["bob@example.com", "bob \"elvis\" wilson"] ]
```

### Custom encoding

You can handle exotic encodings with the `encoding` option.

```ruby
ImportUserCSV.new(content: "メール,氏名".encode('SJIS'), encoding: 'UTF-8')
```

## TODO
  - Add ability to configure activerecord-import validate: Bool option.
  - Allow setting a default attribute on columns.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/desheikh/activerecord_csv_importer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
