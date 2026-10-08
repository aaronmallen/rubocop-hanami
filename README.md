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

### Hanami/EnvAccess

Hanami settings give each value a name, a type and a check at boot. A raw `ENV` read skips all three, and a missing
variable shows up at request time. This cop flags `ENV` and `::ENV`, reads and writes alike.

```ruby
# bad
class Mailers::Welcome
  def from = ENV.fetch("MAIL_FROM")
end

# good
class Mailers::Welcome
  include Deps["settings"]

  def from = settings.mail_from
end
```

It checks every Ruby file but skips settings, providers, `config/app.rb`, `config/puma.rb`, `bin`, `db` and `spec`,
where `ENV` belongs.

### Hanami/ActionCallOverride

`Hanami::Action#call(env)` is the Rack entry point. It builds the request and response, runs callbacks and params
validation, then calls `handle`. Defining `call` replaces all of that. This cop flags `def call` in an action.

```ruby
# bad
class Actions::Home::Show < App::Action
  def call(env)
    [200, {}, ["hi"]]
  end
end

# good
class Actions::Home::Show < App::Action
  def handle(request, response)
    response.body = "hi"
  end
end
```

A class counts as an action when it lives in a file under `actions` or inherits from one of `ParentClasses`. The
cop skips a `call` that calls `super`, so a base action may wrap `call` on purpose.

```yaml
Hanami/ActionCallOverride:
  ParentClasses:
    - Hanami::Action
    - MyApp::Action
```

### Hanami/UnvalidatedParams

Without a schema, `request.params` holds raw input: strings, any keys, no coercion. This cop flags `[]`, `fetch`
and `dig` on the params of the first argument of `handle`, whatever it is named, in an action that declares no
`params` or `contract`.

```ruby
# bad
class Actions::Users::Show < App::Action
  def handle(request, response)
    id = request.params[:id]
  end
end

# good
class Actions::Users::Show < App::Action
  params do
    required(:id).filled(:integer)
  end

  def handle(request, response)
    halt 422 unless request.params.valid?

    id = request.params[:id]
  end
end
```

The cop can't see a `params` declared in a parent action. Name validated base classes in `AllowedParentClasses` to
skip their subclasses:

```yaml
Hanami/UnvalidatedParams:
  AllowedParentClasses:
    - Admin::Action
```

Schemas need `dry-validation`. An app without it can turn the cop off.

### Hanami/ProviderTopLevelRequire

A `require` at the top of a provider file runs when the file loads. Inside `prepare`, it runs only when the
provider prepares, as the Hanami guides show. This cop flags `require` and `require_relative` in a provider outside
`prepare` and `start`.

```ruby
# bad
require "sidekiq"

Hanami.app.register_provider(:sidekiq) do
  start do
    register "sidekiq", Sidekiq
  end
end

# good
Hanami.app.register_provider(:sidekiq) do
  prepare do
    require "sidekiq"
  end

  start do
    register "sidekiq", Sidekiq
  end
end
```

### Hanami/UnwrappedStep

dry-operation halts on failure only through `step`. A bare call to a method that returns a Result drops the
`Failure`, and the flow carries on as if it worked. This cop flags such a call in an operation's flow.

```ruby
# bad
class Operations::CreateUser < App::Operation
  def call(input)
    validate(input)
    user_repo.create(input)
  end

  private

  def validate(input)
    input[:email] ? Success(input) : Failure(:no_email)
  end
end

# good
class Operations::CreateUser < App::Operation
  def call(input)
    attrs = step validate(input)
    step create(attrs)
  end
end
```

With no types to go on, the cop works within one class. A method returns a Result when its last expression, or a
`return`, is `Success(...)` or `Failure(...)`. A flow method is one of `FlowMethods` or a name the class passes to
`operate_on`. The cop skips a call whose value is assigned, used as a receiver or passed on, and it can't see
Results from injected dependencies.

```yaml
Hanami/UnwrappedStep:
  FlowMethods:
    - call
```

### Hanami/SliceNamespace

Zeitwerk expects `slices/admin/actions/users/index.rb` to define `Admin::Actions::Users::Index`. A mismatch raises
at load time, often far from the file at fault. This cop checks that each top-level `module` and `class` in a slice
opens the slice's namespace.

```ruby
# slices/admin/actions/users/index.rb

# bad
module Backoffice
  module Actions
  end
end

# good
module Admin
  module Actions
  end
end
```

The cop camelizes the slice's directory, so `admin_panel` gives `AdminPanel`, and checks only the first segment of
each name. Zeitwerk checks the rest. For nested slices, the innermost one counts. Name slices that don't camelize
plainly in `Inflections`:

```yaml
Hanami/SliceNamespace:
  Inflections:
    api: API
```

It skips slice routes, slice settings and slice `db`, where files may take another form.

## License

[MIT](LICENSE)
