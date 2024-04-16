---
title: System Design - Youtube
category:
  - System Design
tag:
  - System Design
abbrlink: 241d
date: 2024-04-20 12:42:10
keywords:
description:
---

## 1. Understand the problem and establish design scope
* What features are important: Ability to upload a video and watch a video
* What clients do we need to support: Mobile apps, web browsers, and smart TV
* How many daily active users do we have: 5 million
* What is the average daily time spent on the product: 30 minutes
* Do we need to support international users: Yes, a large percentage of users are international users
* What are the supported video resolutions: The system accepts most of the video resolutions and formats
* Is encryption required: Yes
* Any file size requirement for videos: The maximum allowed video size is 1GB
* Can we leverage the existing cloud infrastructures provided by Amazon, Google, or Microsoft: Yes
 
A video streaming service should have the following features:
* Ability to upload videos fast
* Smooth video streaming
* Ability to change video quality
* Low infrastructure cost
* High availability, scalability, and reliability requirements
* Support mobile apps, web browser, and smart TV

### 1.1 Back of the envelope estimation
* Product has 5 million daily active users (DAU)
* Users watch 5 videos per day
* 10% of users upload 1 video per day
* Average video size is 300 MB
* Total daily storage space needed: 5 million * 10% * 300 MB = 150TB
* CDN cost: Assume 100% of traffic is served from CDN service, the average cost per GB is 0.02, cost could be 5 million * 5 videos * 0.3GB * 0.02 = 150,000 per day


## 2. Propose high-level design and get buy-in
Reasons of why we choose not to build everything by ourselves:
* Within the limited interview time frame, choosing the right technology to do a job right is more important than explaining how the technology works in detail. For instance, mentioning blob storage for storing source videos is enough for the interview.
* Building scalable blob storage or CDN is extremely complex and costly. Even Netflix or Facebook do not build everything themselves.

![Components of System](/images/System-Design/Interview/14-components-of-system.jpg)

* Client: computer, mobile phone, and smartTV
* CDN: Videos are stored in CDN. When you press play, a video is streamed from the CDN
* API Servers: Everything else except video streaming goes through API servers, including feed recommendation, generating video upload URL, updating metadata database and cache, user signup, etc

### 2.1 Video uploading flow
![Video Uploading Flow](/images/System-Design/Interview/14-video-uploading-flow.jpg)

* User: watch videos on devices, like a computer, mobile phone, or smartTV
* Load balancer: evenly distribute requests among API servers
* API servers: All user requests go through API servers except video streaming
* Metadata DB: Video metadata are stored in Metadata DB. It is sharded and replicated to meet performance and high availability requirements.
* Metadata cache: video metadata and user objects are cached
* Original storage: A blob storage system is used to store original videos.
* Transcoding servers: Video transcoding is also called video encoding. It is the process of converting a video format to other formats, which provide the best video streams possible for different devices and bandwidth capabilities
* Transcoded storage: It is a blob storage that stores transcoded video files
* CDN: Videos are cached in CDN. When you click the play button, a video is streamed from the CDN
* Completion queue: a message queue that stores information about video transcoding completion events
* Completion handler: a list of workers that pull event data from the completion queue and update metadata cache and database

#### 2.1.1 upload the actual video
![Upload the Actual Video](/images/System-Design/Interview/14-upload-actual-video.jpg)

1. Videos are uploaded to the original storage
2. Transcoding servers fetch videos from the original storage and start transcoding
3. Once transcoding is complete, the following two steps are executed in parallel:
    1. For video storage:
        * Transcoded videos are sent to transcoded storage
        * Transcoded videos are distributed to CDN
    2. For video metadata:
        * Transcoding completion events are queued in the completion queue
        * Workers in completion handler pull event data from the queue, and update the metadata database and cache
4. API servers inform the client that the video is successfully uploaded and is ready for streaming

#### 2.1.2 update the metadata
![Update the Metadata](/images/System-Design/Interview/14-update-metadata.jpg)

While a file is being uploaded to the original storage, the client in parallel sends a request to update the video metadata. The request contains video metadata, including file name, size, format, etc. API servers update the metadata cache and database

### 2.2 Video streaming flow
**Downloading** means the whole video is copied to your device, while **streaming** means your device continuously receives video streams from remote source videos. When you watch streaming videos, your client loads a little bit of data at a time so you can watch videos immediately and continuously.
Before we discuss video streaming flow, let us look at the **streaming protocol**. This is a standardized way to control data transfer for video streaming. Popular streaming protocols are:
* MPEG–DASH
* Apple HLS
* Microsoft Smooth Streaming
* Adobe HTTP Dynamic Streaming

When we design a video streaming service, we have to choose the right streaming protocol to support our use cases.
Videos are streamed from CDN directly. The edge server closest to you will deliver the video. Thus, there is very little latency.


## 3. Design deep dive
### 3.1 Video transcoding
When you record a video, the device (usually a phone or camera) gives the video file a certain format. If you want the video to be played smoothly on other devices, the video must be encoded into compatible bitrates and formats. 
Bitrate is the rate at which bits are processed over time. A higher bitrate generally means higher video quality. High bitrate streams need more processing power and fast internet speed.
Video transcoding is important for the following reasons:
* Raw video consumes large amounts of storage space. An hour-long high definition video recorded at 60 frames per second can take up hundred GB of space
* Many devices and browsers only support certain types of video formats
* Deliver higher resolution video to users who have high network bandwidth and lower resolution video to users who have low bandwidth
* To ensure a video is played continuously, switching video quality automatically or manually based on network conditions is essential for smooth user experience

Many types of encoding formats are available; however, most of them contain two parts:
* Container: contain the video file, audio, and metadata
* Codecs: compression and decompression algorithms aim to reduce the video size while preserving the video quality

### 3.2 Directed acyclic graph (DAG) model
Different content creators may have different video processing requirements:
* some content creators require watermarks on top of their video
* some provide thumbnail image
* some upload high definition videos

To support different video processing pipelines and maintain high parallelism, we need to add some level of abstraction and let client programmers define what tasks to execute. For example, Facebook's streaming video engine uses a directed acyclic graph (DAG) programming model, which defines tasks in stages so they can be executed sequentially or parallelly.

![DAG model](/images/System-Design/Interview/14-DAG-model.jpg)

The original video is split into video, audio, and metadata. Here are some tasks that can be applied on a video file:
* Inspection: Make sure videos have good quality and are not malformed
* Video encodings: Videos are converted to support different resolutions, codec, bitrates, etc
* Thumbnail: Thumbnails can either be uploaded by a user or automatically generated by the system
* Watermark: An image overlay on top of your video contains identifying information about your video

### 3.3 Video transcoding architecture
![Video Transcoding Architecture](/images/System-Design/Interview/14-video-transcoding-arch.jpg)

#### 3.3.1 Preprocessor
The preprocessor has 4 responsibilities:
1. Video splitting: Video stream is split into smaller **Group of Pictures**(GOP) alignment. Each chunk is an independently playable unit, usually a few seconds in length.
2. Some old mobile devices or browsers might not support video splitting. Preprocessor split videos by GOP alignment for old clients.
3. DAG generation: The processor generates DAG based on configuration files client programmers write
4. Cache data: The preprocessor is a cache for segmented videos. For better reliability, the preprocessor stores GOPs and metadata in temporary storage. If video encoding fails, the system could use persisted data for retry operations.

#### 3.3.2 DAG scheduler
The DAG scheduler splits a DAG graph into stages of tasks and puts them in the task queue in the resource manager. 
![DAG Scheduler Example](/images/System-Design/Interview/14-DAG-scheduler-example.jpg)

The original video is split into three stages:
1. video, audio, and metadata
2. The video file is split into two tasks
    1. video encoding
    2. thumbnail
3. The audio file requires audio encoding as part of the stage 2 tasks

#### 3.3.3 Resource manager
The resource manager is responsible for managing the efficiency of resource allocation:
* Task queue: a priority queue that contains tasks to be executed
* Worker queue: a priority queue that contains worker utilization info
* Running queue: contains info about the running tasks and workers
* Task scheduler: picks the optimal task/worker, and instructs the chosen task worker to execute the job

![Resource Manager](/images/System-Design/Interview/14-resource-manager.jpg)

The resource manager works as follows:
1. Get the highest priority task from the task queue
2. Get the optimal task worker to run the task from the worker queue
3. Instruct the chosen task worker to run the task
4. Bind the task/worker info and puts it in the running queue
5. Remove the job from the running queue once the job is done

#### 3.3.4 Task workers
Task workers run the tasks which are defined in the DAG. Different task workers may run different tasks.

#### 3.3.5 Temporary storage
The choice of storage system depends on factors like data type, data size, access frequency, data life span, etc. For instance:
* memory store: metadata is frequently accessed by workers, and the data size is usually small
* blob storage: video or audio data

#### 3.3.6 Encoded video
Encoded video is the final output of the encoding pipeline. an example of the output: funny_720p.mp4

### 3.4 System optimizations
#### 3.4.1 Speed optimization: parallelize video uploading
Uploading a video as a whole unit is inefficient. We can split a video into smaller chunks by GOP alignment. This allows fast resumable uploads when the previous upload failed. The job of splitting a video file by GOP can be implemented by the client to improve the upload speed.
![Video Split](/images/System-Design/Interview/14-video-split.jpg)

#### 3.4.2 Speed optimization: place upload centers close to users
Set up multiple upload centers across the globel. 

#### 3.4.3 Speed optimization: parallelism everywhere
Build a loosely coupled system and enable high parallelism. The flow of how a video is transferred from original storage to the CDN is shown below:

![Original Video Workflow](/images/System-Design/Interview/14-original-video-workflow.jpg)

To make the system more loosely coupled, we introduced message queues:

![Optimized Video Workflow](/images/System-Design/Interview/14-optimized-video-workflow.jpg)

* Before: the encoding module must wait for the output of the download module
* After: the encoding module does not need to wait for the output of the download module anymore

#### 3.4.4 Safety optimization: pre-signed upload URL
To ensure only authorized users upload videos to the right location, we introduce pre-signed URLs:

![Pre-signed Upload URL](/images/System-Design/Interview/14-presigned-upload-url.jpg)

1. Client makes a HTTP request to API servers to fetch the pre-signed URL, which gives the access permission to the object identified in the URL. The term pre-signed URL is used by uploading files to Amazon S3. 
2. API servers respond with a pre-signed URL
3. Once the client receives the response, it uploads the video using the pre-signed URL.

#### 3.4.5 Safety optimization: protect your videos
To protect copyrighted videos:
* Digital rights management (DRM) systems: Apple FairPlay, Google Widevine, and Microsoft PlayReady
* AES encryption: You can encrypt a video and configure an authorization policy. This ensures that only authorized users can watch an encrypted video
* Visual watermarking: Place an image overlay on top of video that contains identifying information

#### 3.4.6 Cost-saving optimization
Few optimizations to reduce CDN cost:
* Only serve the most popular videos from CDN, and other videos from our high capacity storage video servers
* For less popular content, we don't need to store many encoded video versions
* Some videos are only popular in certain regions. No need to distribute these videos to other regions.
* Build your own CDN and partner with Internet Service Providers (ISPs).

All those optimizations are based on content popularity, user access pattern, video size, etc. It is important to analyze historical viewing patterns before doing any optimization.

### 3.5 Error handling
Two types of errors exist:
* Recoverable error: video segment fails to transcode. Solution: retry the operation a few times; If the task continues to fail, returns a proper error code to the client
* Non-recoverable error: malformed video format, system stops the running tasks associated with the video and returns the proper error code to the client

Typical errors for each system component:
* Upload error: retry a few times
* Split video error: if older versions of clients cannot split videos by GOP alignment, the entire video is passed to the server
* Transcoding error: retry
* Preprocessor error: regenerate DAG diagram
* DAG scheduler error: reschedule a task
* Resource manager queue down: use a replica
* Task worker down: retry the task on a new worker
* API server down: API servers are stateless so requests will be directed to a different API server
* Metadata cache server down: data is replicated multiple times. If one node goes down, can still access other nodes to fetch data
* Metadata DB server down:
    * Master is down: promote one of the slaves to act as the new master
    * Slave is down: use another slave for reads and bring up another database server to replace the dead one


## 4. Wrap up
Additional talking points:
* Scale the API tier: Because API servers are stateless, it is easy to scale API tier horizontally
* Scale the database: You can talk about database replication and sharding
* Live streaming: differences between video and live streaming
    * Live streaming has a higher latency requirement, might need a different streaming protocol
    * Live streaming has a lower requirement for parallelism because small chunks of data are already processed in real-time
    * Live streaming requires different sets of error handling. Error handling shouldn't take too much time
* Video takedowns: Videos that violate copyrights, pornography, or other illegal acts shall be removed

