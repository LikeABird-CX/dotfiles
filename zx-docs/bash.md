# Compare file modification times

You can compare file modification times with test, using -nt (newer than) and -ot (older than) operators:

```bash
if [ "$file1" -ot "$file2" ]; then
    cp -f "$file2" "$file1"
fi
```
http://stackoverflow.com/questions/14802807/compare-files-date-bash

# How to copy symbolic links?

> I use `cp -av` for most of my heavy copying.

http://superuser.com/questions/138587/how-to-copy-symbolic-links

# How can I make 'rm' move files to the trash can?

## Bad Idea

Using rm to move files to trash is like weed. It is common and pleasuring but can be bad for you in the future. ;)

You really need control yourself when using `rm`.

## Don't use rm

Imagine, you get used to rm moving to trash and make a habit of it. Sure, your system is safe but when you log into a friend's (or your wife's or your boss') notebook and have to delete something? You'll be actually using the real `rm` - deleting those files forever. It's a bad habit, and you need to know that.

So instead, install `rmtrash` and make a habit of using it:

```bash
# install rmtrash, (either from the macports or by the brew.)
$ alias trash="rmtrash"
$ alias   del="rmtrash"       # del / trash are shorter than rmtrash
```

http://apple.stackexchange.com/questions/17622/how-can-i-make-rm-move-files-to-the-trash-can