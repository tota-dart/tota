# Tota

Tota is a simple and elegant static-site generator, written in Dart.
Great for personal websites, side-projects, blogs, documentation, and more.

## Install

#### Pre-requisites:
  * Install **[Dart](https://dart.dev/get-dart)** 2.3+

Then, activate the package globally:

```bash
pub global activate tota
```

## Quick start

#### Setup your site

```bash
mkdir -p blog && cd blog
tota init
```

#### Create a new post

```bash
tota new "Hello, world!"
vim pages/hello-world.md
```

#### Generate static files

```bash
tota build
```

#### Deploy site

```bash
tota deploy
```


See `--help` for usage information.
