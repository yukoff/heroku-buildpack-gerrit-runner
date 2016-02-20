# Heroku buildpack for running gerrit

This buildpack is created to run gerrit code review on heroku. It doesn't seem to be suitable for production usage
due heroku's worker implementation (eg. any changes done to filesystem will be lost on restart).

## How it is used

First of all, you should either build or download gerrit. See https://gerrit-review.googlesource.com/Documentation/dev-readme.html
for more information on building gerrit.

Next, follow required steps from https://gerrit-review.googlesource.com/Documentation/install.html (actually,
in case of heroku you should configure required add-ons and configure gerrit correspondingly during site
initialization https://gerrit-review.googlesource.com/Documentation/install.html#init).

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
