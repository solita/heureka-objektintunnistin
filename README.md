# Heureka Objektintunnistin

A configurable object detection application for iPad. This application is part of the exhibition [Me, Myself and AI](https://www.heureka.fi/nayttely/tekoaly/) at [Heureka](https://www.heureka.fi/), the Finnish Science Centre.

![Screenshot](screenshot.jpeg?raw=true "Main recognition view")

## License

Heureka Objektintunnistin is licensed under the terms of the [GNU GENERAL PUBLIC LICENSE Version 3](LICENSE).

## Dependencies

Apart from iOS native frameworks, the application uses [SPConfetti framework](https://github.com/ivanvorobei/SPConfetti) to make the _mission complete_ view a tad fancier. For this dependency, you don't need to do anything special, it will be automatically picked up through Swift Package Manager.

[SwiftLint](https://github.com/realm/SwiftLint) is configured as optional development time dependency through Ruby Gemfile.

The AI models used in the app are based on [Darknet YOLOv3](https://github.com/pjreddie/darknet) and [Ultralytics YOLOv5](https://github.com/ultralytics/yolov5). The model files used in the application are stored in [Git Large File Storage](https://git-lfs.github.com/). Before you clone the directory, please install the `git-lfs` tool in order to be able to fetch the model files.

## Building

Once you have cloned the repository, you can use either Xcode IDE or the command line tools to build the app. Recommended running environment is the device that the app is designed for (iPad). It is possible to run the app in simulator, but real hardware (iPad) is needed for the live camera feed and recognition features. If you're on a M1 mac, it is possible to run the app also in MacOS (motion sensing features not supported).

## Configuration

The user interface and behaviour can be configured through iTunes file sharing, by uploading a custom configuration JSON file `config.json` and corresponding image files to the device running the app.

Application ships with a default configuration that you can find in the source code under [tunnistin/tunnistin/configuration/config.json](tunnistin/tunnistin/configuration/config.json). Also the default image assets are shipped with the app.

### Top level JSON

| Top level fields           | Format   | Default      |  Usage                                                                                                                                                                              |
| -------------------------- | -------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `languages`                | [string] | ["en", "fi"] |  Array of language identifiers used in `objects` and `uiTexts` fields localisation arrays                                                                                           |
| `displaylanguages`         | [string] | ["fi", "en"] | Order of languages on screen when localised texts are displayed. Use subset of `languages` array                                                                                    |
| `modelId`                  | integer  | 2            | identifies the AI model to use for object detection - use _1_ for YOLOv3 and _2_ for YOLOv5                                                                                         |
| `confidenceThreshold`      | double   | 0.65         | A value between 0.0-1.0. Model inference results with confidence below given value are ignored                                                                                      |
| `zoomFactor`               | double   | 1.0          |  A value between 1.0 - 10.0. Specifies a zoom factor for the camera.                                                                                                                |
| `requiredIntersection`     | double   | 0.9          | A value between 0.0-1.0. Specifies the portion of intersection between subsequent detection rectangles required to keep detection timer running. Smaller value => allow more motion |
| `borderWidth`              | double   | 4.0          | Width of the object detection borders in points                                                                                                                                     |
| `cornerRadius`             | double   | 0.0          | Object detection corner radius in points. radius                                                                                                                                    |
| `objectTimerLength`        | double   | 2.0          | Time (seconds) required to "catch" a target object, i.e. how long it takes for the objectTimer circle to fill up                                                                    |
| `objectTimerType`          | string   | "pie"        | Specifies the object timer visualisation type. In addition to default, "bar" and "text" can be used but they do not have the completion visualisation as the "pie" type.            |
| `resultsViewWidth`         | double   | 0.14         | A value between 0.0-1.0 - fraction of the width of screen reserved for target objects list                                                                                          |
| `motiionSensorPause`       | double   | 3.0          | Specifies how long the motion sensor events are paused after connecting the device to charger to avoid immediate dismissal of the pause/idle view                                   |
| `objectColor               | string   | "#D20F41"    | Specifies object detection border color. If not specified, application will generate random colors per object class, unless overridden for a class in `objects` array               |
| `objectTextColor           | string   | "#FFF9EF"    | Specifies color of text drawn over `objectColor`.                                                                                                                                   |
| `fontName`                 | string   | "SF Pro"     | Specifies font to be used in UI. Value can be any iOS default font, e.g. "Impact", or a font that is shipped with the app.                                                          |
| `awardGifHeight`           | double   | 150.0        | Height of the award gif animation on Award view. If zero, the gif will not be shown. Award view texts will scale down if large value is used.                                       |
| `awardGifDuration`         | double   | 3.0          | Duration of the gif animation                                                                                                                                                       |
| `awardDisplayTime`         | double   | 8.0          | Specifies how long (seconds) the award view will be shown when all target objects have been detected.                                                                               |
| `pauseImageHeight`         | double   | 0.0          | Height of the pause image on idle screen. If zero, the image will not be shown.                                                                                                     |
| `idleDetectionCycles`      | integer  | 100          | How many motion sensor cycles (0.2 seconds each) with no movement are required to turn on the pause mode.                                                                           |
| `motionDetectionThreshold` | double   | 0.015        | Specifies the total motion required to reset idle detection cycles calculated from all the three axis                                                                               |
| `showMotionValues`         | boolean  | false        | When true, an overlay with current total motion + idle cycles is shown on screen for debugging purposes                                                                             |
| `screenColor`              | string   | "#D20F41"    | Background color used in pause / award / initialising screens                                                                                                                       |
| `targetObjects`            | [string] |              | Objects that user needs to find to complete the objective. List of classes in YOLO object list. Default list is ["cell phone","handbag", "toothbrush", "cup", "book"]               |
| `uiTexts`                  | [uiText] |              | User interface texts and their localisations. See `uiText` fields below.                                                                                                            |
| `objects`                  | [object] |              | Object classes for detection, their localisation and custom color and confidence threshold values. See `object` fields below.                                                       |

### Screen texts configurations

| `uiText` fields | Format   | Default |  Usage                                                                                                                                                                           |
| --------------- | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `textId`        | string   |         | logical name of the text: "text_init" (initialising screen title), "text_idle" (pause screen title), "text_success" (award view title), "text_found_items" (award view subtitle) |
| `localisations` | [string] |         | localisations for the text in the order of main field array `localisations`                                                                                                      |

### Detected objects configurations

| `object` fields       | Format   | Default |  Usage                                                                             |
| --------------------- | -------- | ------- | ---------------------------------------------------------------------------------- |
| `classification`      | string   |         | YOLO object class name. Objects not listed will not show in the app.               |
| `localisations`       | [string] |         | Localisations for the object name in the order of main field array `localisations` |
| `color`               | string   |         | Override for main config `objectColor` per object.                                 |
| `confidenceThreshold` | double   |         | Override for main config `confidenceThreshold` per object.                         |

### Target object images configuration

The classes in `targetObjects` list are visualised in the App on the side panel. Corresponding images for the default target objects are shipped with the app. It is possible to change the default target object images shown on the left side panel, or replace them with other target object classes by adding new files to application through iTunes.

The image files can be in `pdf`, `png` or `jpg` format. Format is identified by respective file extension. If app finds image files with name _classname_._ext_ sent through iTunes that match the current target object classes, these images are shown in the application UI on the target objects list. In case no such image is found, a question mark icon will be displayed instead.

### Award view and pause view images configuration

Award view GIF animation and pause view static image can be customised as well.

To replace the default award view GIF, add a new gif animation named `award.gif` to the app via iTunes. Note that also the main configuration `awardGifHeight` field must be greater than zero for the image to show in the app. Use `awardGifDuration` field to control the playback speed.

To show an image on the pause screen, add a new image file named `pause.[png|pdf|jpg]` ti the app via iTunes. Similarly, `pauseImageHeight` field must be greater than zero to for the image to show in the app.
