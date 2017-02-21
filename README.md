# GYI
A GUI for the command-line program 'youtube-dl,' hence the name 'GYI' (Graphical Youtube-dl Interface). Used for downloading videos from websites (YouTube, Vimeo, Crunchyroll, etc.)

## Features
* The youtube-dl executable is embedded in the app, so there is no need to download it through traditional methods (curl, wget, homebrew, etc.).
* GYI can download a single video at a time, or a whole group of videos (like a YouTube playlist).
* The user can put in (and save) account information for multiple websites. (This is useful when some websites require user authentication or a premium account of some sort to access higher quality videos, like Crunchyroll, among others.) The user may also delete accounts.
* The user may choose the destination they want to save the video(s) to. Also, they have the option of keeping a specific folder as their default output folder.
* The user may choose to automatically update the underlying youtube-dl executable file upon launching the app. At this time, it is the only way to update the executable.
* Progress indicators for both the current video being downloaded and for an entire playlist to show overall progress.


## Notes
GYI is in its early stages, though it is a working app for the most part, albeit without many features. Please note that it hasn't been tested on all websites. Theoretically, the actual downloading should work for any website that youtube-dl supports, but at this time, the way I parse the strings returned from the NSTask could very well not work on all websites if their format isn't the same for all (youtube-dl supported) websites.

GYI will automatically download the highest quality video possible. Again, **some** websites require authentication (which is done through GYI) to be able to download the actual highest quality available on the website.

## Built With
* [youtube-dl](https://github.com/rg3/youtube-dl)

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments
* The real credit goes to all those that work on youtube-dl. It does all the hard work in GYI.

