SpreeProductsImport
===================

[![Build Status](https://travis-ci.org/secoint/spree_products_import.svg?branch=master)](https://travis-ci.org/secoint/spree_products_import)

This extension allows users to import products from a CSV file.

## Requirements

* Spree 3.4
* Sidekiq (import processed in background)

## Installation

1. Add this extension to your Gemfile with this line:
  ```ruby
  gem 'spree_products_import', github: 'secoint/spree_products_import'
  ```

2. Install the gem using Bundler:
  ```ruby
  bundle install
  ```

3. Restart your server

  If your server was running, restart it so that it can find the assets properly.

## CSV file format and supported attributes

|CSV column|Product attribute|Processor|
|---|---|---|
|`name`|`name`|Processed as is|
|`description`|`description`|Processed as is|
|`price`|`price`|Replace commas with dots and cast to Float|
|`availability_date`|`available_on`|Processed as is (if `availability_date` can't be parsed to a Date, it will be ignored)|
|`slug`|`slug`|Processed as is|
|`stock_total`|`master.total_on_hand`|Product master's stock total in default location is being replaced by this value|
|`category`|`taxons`|Find existing Taxon by this value (or create one) and add it to Product|

### CSV file example

```
;name;description;price;availability_date;slug;stock_total;category
;Ruby on Rails Bag;Animi officia aut amet molestiae atque excepturi. Placeat est cum occaecati molestiae quia. Ut soluta ipsum doloremque perferendis eligendi voluptas voluptatum.;22,99;2017-12-04T14:55:22.913Z;ruby-on-rails-bag;15;Bags
```

## Contributing

* Fork it.
* Make changes.
* Create a pull request.

Copyright (c) 2017 Denis Lukyanov, released under the New BSD License
