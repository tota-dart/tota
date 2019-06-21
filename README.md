# Tota

A simple and elegant framework for generating static sites.
Great for personal websites, blogs, documentation, and more.

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
tota init blog
cd blog
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
