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

## License

[MIT](LICENSE)
