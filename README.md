# Showcase

## Project Description
An app to meet Udacity iOS Developer Nanodegree Final Project requirement.

## Project Focus Areas
- Swift
- Core Data
- NSURLSession
- NSFetchedResultsController
- Firebase
- PDFKit
- AVKit

## App Specification

This app allows theater/acting students to review and print scripts that have been uploaded by their instructor. In addition, the student may record practice videos for a given script.  Core data/local storage is used to maintain the downloaded scripts and recordings.

The app has the following primary views:

- **Login**: Login screen to access the application
- **Scripts**: List the current set of scripts provided by the instructor.
- **Favorites**: List of scripts that have been favorited by the student.
- **Script**: A PDF viewer that allows the student to review and print the script.  They may also flag it as a “favorite”.
- **Videos**: List of videos that the student has recorded for a given script.

These screens are described in detail below.

### Login

When the app launches the student will be required to login.  They may use email, Facebook or Google for account access. 

### Scripts

This tab has a list of scripts grouped by category (comedy, e.g.).  The script meta data is hosted in a Firebase database and will be stored on the device in core data.  The table allows a student to select a script to review.

### Favorites

This tab has the scripts that have been selected by the student as a “favorite”.  This table also allows a student to select a script to review.

### Script

The screen provides a view the script’s PDF.  The document is downloaded from Firebase storage and stored locally.  In addition, it creates a custom watermark based on the logged in student. This permits easy identification of printed copies brought to the studio.  Full functional printing from the app is allowed if there is an available AirPrint Printer.

### Videos

This screen allows a student to maintain a list of videos recorded for a given script.  The maximum video is 90 seconds primarily geared to practicing short monologues.  The recorded video is black and white and captioned with the script name, time & date.  It is also watermarked with the application logo.  New videos are added by tapping the “Capture Video” button.  After an item is added to the list, tapping it will launch playback. The table item may be swiped to the left to reveal options to share or delete the video.
