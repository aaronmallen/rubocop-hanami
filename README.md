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

## License

[MIT](LICENSE)
