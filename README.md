# RuboCop::Hanami

[RuboCop](https://rubocop.org) cops for [Hanami](https://hanamirb.org) apps and slices.

## Installation

Add the gem to your Gemfile:

```ruby
gem "rubocop-hanami", require: false
```

Or, from [gem.coop](https://gem.coop):

```ruby
gem "rubocop-hanami", require: false, source: "https://gem.coop/@aaron"
```

Then load it as a plugin in `.rubocop.yml`:

```yaml
plugins:
  - rubocop-hanami
```

## Cops

### Hanami/SliceExports

A slice that never calls `export` lets every other slice import any key from its container. This cop flags a slice
with no `export`, an `export` that takes anything but a literal array of strings, and any key the settings reject.

```ruby
# bad
class Admin::Slice < Hanami::Slice
end

# good
class Admin::Slice < Hanami::Slice
  export ["repos.queries"]
end
```

To let a slice leave out `export`, turn off `RequireExport`. The cop then checks only the keys of the slices that
call it:

```yaml
Hanami/SliceExports:
  RequireExport: false
```

`AllowedExports` and `ForbiddenExports` take strings, matched exactly, and regular expressions. With no
`AllowedExports`, any key not forbidden passes.

```yaml
Hanami/SliceExports:
  AllowedExports:
    - repos.queries
    - !ruby/regexp /\Aoperations\./
  ForbiddenExports:
    - repos.mutations
```

It checks `config/slices/*.rb` and `slices/*/config/slice.rb`, and treats a class as a slice when it inherits from
one of `ParentClasses`. If your slices share a base class, name it there:

```yaml
Hanami/SliceExports:
  ParentClasses:
    - MyApp::Slice
```

### Hanami/ContainerLookup

A lookup such as `Admin::Slice["repos.user_repo"]` hides a dependency from the constructor, so a test can't pass a
stub through `new`. This cop flags a lookup by literal string key on `Hanami.app`, on `Hanami.app.slices[...]`,
and on any constant that ends in `Slice`.

```ruby
# bad
class Admin::Actions::Users::Show < Admin::Action
  def handle(request, response)
    user = Admin::Slice["repos.user_repo"].find(request.params[:id])
  end
end

# good
class Admin::Actions::Users::Show < Admin::Action
  include Deps["repos.user_repo"]

  def handle(request, response)
    user = user_repo.find(request.params[:id])
  end
end
```

It also catches code that reaches into another slice's container without `import`.

It checks `app`, `slices` and `lib`, but skips `config`, slice `config` and `spec`, where providers, routes and specs
need lookups. To skip a constant that wraps the container on purpose, name it in `AllowedReceivers`:

```yaml
Hanami/ContainerLookup:
  AllowedReceivers:
    - Admin::Slice
```

### Hanami/AppReferenceInSlice

A slice should depend only on its own container and what it imports. `Hanami.app` ties it to the host app, so it
can't be moved, extracted or loaded alone. This cop flags `Hanami.app` in `slices`, but skips slice `config`, where
settings and providers may need the app.

```ruby
# bad
class Admin::Actions::Users::Index < Admin::Action
  def handle(request, response)
    Hanami.app.settings.page_size
  end
end

# good
class Admin::Actions::Users::Index < Admin::Action
  include Deps["settings"]

  def handle(request, response)
    settings.page_size
  end
end
```

When `Hanami/ContainerLookup` is on, this cop leaves lookups such as `Hanami.app["logger"]` to it, so a line isn't
flagged twice.

To flag constants from the host app too, name its top-level modules in `AppNamespaces`. The cop can't learn them
from one file, so the list starts empty. Hanami's generator gives each slice a base action that inherits from
`MyApp::Action`, so expect to disable the cop for that file.

```yaml
Hanami/AppReferenceInSlice:
  AppNamespaces:
    - MyApp
```

### Hanami/RelationOutsideRepo

Repos are the boundary to the database. When an action, operation or view queries a relation, query logic spreads
across layers. This cop flags a relation, or the ROM container that hands them out, in `include Deps[...]` outside
`repos`, `relations` and `db`.

```ruby
# bad
class Operations::ListUsers
  include Deps["relations.users"]

  def call = users.where(active: true).to_a
end

# good
class Operations::ListUsers
  include Deps["repos.user_repo"]

  def call = user_repo.active
end
```

`RelationKeyPrefixes` names the start of a relation's key, and `ROMKeys` names the keys of the ROM container:

```yaml
Hanami/RelationOutsideRepo:
  RelationKeyPrefixes:
    - relations.
  ROMKeys:
    - db.rom
    - persistence.rom
```

### Hanami/PersistenceInAction

Some teams want actions to do only HTTP work and hand the rest to an operation, so persistence and business rules
live in one place that tests can call without a request. This cop flags a repo or relation in an action's
`include Deps[...]`. It is off by default; turn it on if your team works this way.

```ruby
# bad
class Actions::Users::Create < App::Action
  include Deps["repos.user_repo"]

  def handle(request, response)
    user_repo.create(request.params[:user])
  end
end

# good
class Actions::Users::Create < App::Action
  include Deps["operations.create_user"]

  def handle(request, response)
    create_user.call(request.params[:user])
  end
end
```

`ForbiddenKeyPrefixes` match at the start of any segment of the key, so an imported `search.repos.index` counts
too. `AllowedKeys` takes strings, matched exactly, and regular expressions, to let keys such as a read-only query
repo through:

```yaml
Hanami/PersistenceInAction:
  Enabled: true
  AllowedKeys:
    - repos.user_queries
  ForbiddenKeyPrefixes:
    - repos.
    - relations.
```

It overlaps `Hanami/RelationOutsideRepo` for `relations.` keys, so a relation in an action gets two reports while
both are on.

### Hanami/UnusedDeps

A stale dependency still gets resolved, still boots its provider and still shows up as a constructor argument. This
cop flags a key in `include Deps[...]` whose accessor the class never reads.

```ruby
# bad
class Operations::CreateUser
  include Deps["repos.user_repo", "mailers.welcome"]

  def call(input)
    user_repo.create(input)
  end
end

# good
class Operations::CreateUser
  include Deps["repos.user_repo"]

  def call(input)
    user_repo.create(input)
  end
end
```

A read is a bare call or a call on `self`, the instance variable the kwargs strategy sets, or `send`,
`public_send`, `__send__` or `method` with a literal symbol. The cop skips a class that passes `Deps` anything but
literal keys, or that calls `send` with a name it can't read, and it skips modules.

The cop sees one file, so it flags a dependency that only a subclass reads. Disable it on that line:

```ruby
include Deps["repos.user_repo"] # rubocop:disable Hanami/UnusedDeps
```

## License

[MIT](LICENSE)
