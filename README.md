# Recoll

## Discussion

This repo contains scripts that will build a Docker container that hosts:
- the Recoll search engine
- the web front-end to the Recoll search engine
- the recollstatus script, which will show the status of an in-progress recollindex session
- an Apache2 interface to the files folder

Over the years, I've experimented with a number document search engines.  Most don't have a web front-end, which limited choices to only a handful.  The engine that I initially settled on for long term home lab use was Recoll.  It was nice because I was able to tweak how the results were displayed in the web interface.

Recently, I'd given up on Recoll because I have over 25,000 documents, gathered over the last 12+ years (okay, I'm a digital packrat).  The reason why I'd given up was that the searches via Xapian engine was becoming obscenely slow.  I recently discovered that this was because my desktop and Recoll were fighting for memory, which caused really heavy paging (i.e., a slow desktop).

In the last month or so, I purchased a couple mini-PCs.  One of those became a 40W replacement for my 350W desktop machine.  The other became my home lab machine, running headless. The lab machine also has twice as much memory as the old desktop machine.  I moved a majority of my tools onto the lab machine and, in doing so, tried Recoll again.  Without the memory conflicts, Recoll is once again tolerable.

## Disclaimers
* This instance of Recoll is intended for home labs only.  Putting it on the Internet is a very bad idea, mostly because there's no security built into any part of the container.
* If you are indexing more than 20,000 files, you may notice an excessive slow-down when querying files. If such happens, you might want to consider employing a separate machine as a dedicated host.  For a few thousand of files, this will run nicely on a laptop or desktop machine.
* This is a work-in-progress.  You may notice that the "Edit" function doesn't yet work.  This is because I'm rewriting the code that modifies the metadata in the source documents.  In the screenshot (much below), the first entry is a result for a pdf file that contains additional meta data (e.g., title, author, tags).  The second entry shows the result for a pdf that lacks the metadata.  In short, the metadata is a nice-to-have but doesn't impact the search engine or the results.  I'm also looking at adding a function or service that will search on the tags.  Of course, my constrained resource is "time".

## Installation

1) Edit the build script, to suit your architecture. 
* As is, 8084 is the external port for the web server.  It "masks" port 80 (on the container) because I already run another port 80 service on the lab machine. 
* Port 8083 is the external and internal port, from which you can access the WebUI for Recoll.
* /data/docs is where your files are stored on the host machine.
* /var/www/html/docs is where Recoll thinks the files are stored (inside the container)
* /data/recoll is where Recoll's files are stored on the host machine.
* /root/.recoll is where Recoll thinks its files are stored (inside of the container).  Note: this provides persistence for the search data.  In other words, you won't have to reindex your files every time that you stop/start your machine (or the container).

2) Edit the result.tpl file to suit yourself.  The result.tpl file is the template for the individual entries in your search output.  I've tweaked it for my own use.  You may want to untweak it and/or add your own modifications.  If you want the original version, visit the link for docker-recoll-webui (below).

3) docker run -itd --name recoll -p 8084:80 -p 8083:8080 -v /data/docs:/var/www/html/docs -v /data/recoll:/root/.recoll ghcr.io/jiangchuanso/recoll-webui:v1.0.0

4) Point a browser at http://localhost:8083.

You can then start/stop the container (without having to re-run the build-image or build scripts) via: 
```
docker stop recoll
docker start recoll
```

## Indexing files
You can index your files by conneting to the container and running the "recollindex" or the "recollindex -z" command.  The latter of these two will erase the existing index and create a new one.  The former will scan and add any new files to the index (and/or remove missing files from the index).  If you want to check the status of an in-progress scan, run the "recollstatus" command.  Example:
```
docker exec -it recoll bash
recollindex -z
recollstatus
```

## The screenshot
![Screenshot](recoll-screenshot.png)
As noted above, the screenshot shows two results for a sarch on "islr analytics" (without the quotes).  Both of the entries are from ebooks that Packt Publishing had offered during their one-free-book-per-day era.

The first result is for a file that has additional metadata embedded in it (think exiftool).  These incldue: title, author, and tags.  The second result is for a file that lacks the embedded metadata.  By default, Recoll includes the ability to extract the metadata from the files, so it was simple to add them to the results.  

The dates shown indicate when I'd copied the file into the folder, not the actual publication dates.  The publisher's file creation date is actually in the metadata and it should be easy enough to extract/display that date, if so desired.

## Wish List
Let me know if there's any features that you want added. While I'll probably balk at modifyiing the core search engine, I'm willing to modify my own code (e.g., what I've done to the web interface).
* Set up a tag search function.
* Finish the Edit function.
* Consider extracting other metadata (e.g., OID, IID, DID).
* I'm also working on migrating this to Kubernetes.

## Sources
* https://www.lesbonscomptes.com/recoll/pages/index-recoll.html
* https://github.com/amsaravi/docker-recoll-webui
* https://github.com/nbeaver/recoll_status
* https://github.com/packetgeek/recoll-web-ui-template (yeah, referencing my own work, not usually "a good thing")
