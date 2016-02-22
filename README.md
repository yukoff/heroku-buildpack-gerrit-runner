# Heroku buildpack for running gerrit

This buildpack is created to run gerrit code review on heroku. It doesn't seem to be suitable for
production usage on heroku just out-of-the-box due to heroku's dyno implementation (they use
so-called ephemeral filesystem, eg. any changes done to filesystem will be lost on restart). More
on this [here](https://devcenter.heroku.com/articles/dynos#ephemeral-filesystem).

However, as a proof of concept it's possible to run gerrit with replication running over github.com
repo (this repo is an example, currently with some manual syncing). This will be described
[later](#basic-idea) on. But even with limited success gerrit's ssh won't be available (git
push/pull over http is possible with http auth).

## <a name"how-to-use"/>How it is used

First of all, you should either build or download gerrit. Check [this](https://gerrit-review.googlesource.com/Documentation/dev-readme.html)
for more information on building gerrit.

Next, follow required steps from [installation guide](https://gerrit-review.googlesource.com/Documentation/install.html)
(actually, in case of heroku you should configure required add-ons and configure gerrit correspondingly during [site
initialization](https://gerrit-review.googlesource.com/Documentation/install.html#init)).

So here are the steps to be taken:
```
java -jar /path/to/gerrit.war init -d /path/to/your/gerrit_application_directory
cd /path/to/your/gerrit_application_directory
find ./ -type d | xargs -I % touch %/.gitignore
git init .git
git add .
git commit
```
On the 3rd line we'll touch .gitignore in every directory to make sure it (dir) will be present on checkout (it is git's
nature not to preserve empty dirs).

Set proper buildpack for your app:
```
heroku buildpacks:set https://github.com/yukoff/heroku-buildpack-gerrit-runner.git
```

Deploy your application by means of `git push heroku master`. During push you'll see something like
```
$ git push heroku master
Counting objects: 10, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 405 bytes | 0 bytes/s, done.
Total 4 (delta 3), reused 0 (delta 0)
remote: Compressing source files... done.
remote: Building source:
remote:
remote: -----> Fetching set buildpack https://github.com/yukoff/heroku-buildpack-gerrit-runner.git... done
remote: -----> gerrit-runner app detected
remote: -----> Installing jvm-common ...  done
remote: -----> Installing OpenJDK 1.7... done
remote:
remote: -----> Discovering process types
remote:        Procfile declares types -> web
remote:
remote: -----> Compressing...
remote:        Done: 111.7M
remote: -----> Launching...
remote:        Released v20
remote:        https://gerrit_application.herokuapp.com/ deployed to Heroku
remote:
remote: Verifying deploy... done.
To https://git.heroku.com/gerrit_application.git
 + XXXXXXX...YYYYYYY master -> master
 ```

## <a name="basic-idea"/>Basic idea running gerrit it the cloud
... or how to make filesystem-backed repositories persistent.

Please note: to make this concept work repos under `${gerrit.basePath}` (those to be replicated)
should be committed with the remote origin properly set (this will be used for fetch), eg.
```
[remote "origin"]
    url = https://github.com/yukoff/heroku-buildpack-gerrit-runner.git
    fetch = refs/*:refs/*
```
Each replicating repo then should be reflected in `${gerrit.sitePath}/etc/replication.config` (make
sure ssh schema is used), eg.
```
[remote "github"]
    url = git@github.com:yukoff/${name}.git
    push = refs/heads/*:refs/heads/*
    push = refs/tags/*:refs/tags/*
    push = +refs/changes/*:refs/changes/*
    push = +refs/notes/*:refs/notes/*
```
or use `push = refs/*:refs/*` as it is done for repos under `${gerrit.basePath}`.

First idea is to do something like following during dyno startup:
```
gerritBasePath=$(git config --file etc/gerrit.config gerrit.basePath)
fetchRepos=$(
find $gerritBasePath/ -type d -name *.git -exec test -f {}/config \; -print |
  while read repoPath; do
    git config --file ${repoPath}/config remote.origin.url > /dev/null || continue;
    git --git-dir ${repoPath} fetch origin
  done;
)
```

The push-work will be done by the replication plugin of gerrit (however there could be issues
making it work), please see [this gist](https://gist.github.com/yukoff/bcdb67811de911f7db92) for
tips on setting up replication.
