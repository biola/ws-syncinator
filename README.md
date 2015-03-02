Banner Syncinator
=================

Banner Syncinator is a temporary tool to sync NetIDs from the legacy WS system into [trogdir-api](https://github.com/biola/trogdir-api).
Eventually, a new process will take over creating NetIDs, but until then this exists to keep WS and trogdir-api in sync.

Requirements
------------
- Ruby
- Redis server (for Sidekiq)
- Read access to WS MySQL database
- trogdir-api installation

Installation
```bash
git clone git@github.com:biola/ws-syncinator.git
cd ws-syncinator
bundle install
cp config/mongoid.yml.example config/mongoid.yml
cp config/settings.local.yml.example config/settings.local.yml
cp config/blazing.rb.example config/blazing.rb
```

Configuration
-------------
- Edit `config/mongoid.yml` accordingly.
- Edit `config/settings.local.yml` accordingly.
- Edit `config/blazing.rb` accordingly.

Running
-------

```ruby
sidekiq -r ./config/environment.rb
```

Deployment
----------
```bash
blazing setup [target name in blazing.rb]
git push [target name in blazing.rb]
```
