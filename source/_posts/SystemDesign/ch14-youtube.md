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

## Step 1 - Understand the problem and establish design scope
* What features are important?: Ability to upload a video and watch a video
* What clients do we need to support?: Mobile apps, web browsers, and smart TV
* How many daily active users do we have?: 5 million
* What is the average daily time spent on the product?: 30 minutes
* Do we need to support international users?: Yes, a large percentage of users are international users
* What are the supported video resolutions?: The system accepts most of the video resolutions and formats
* Is encryption required?: Yes
* Any file size requirement for videos?: The maximum allowed video size is 1GB
* Can we leverage the existing cloud infrastructures provided by Amazon, Google, or Microsoft?: Yes
 
A video streaming service should have the following features:
* Ability to upload videos fast
* Smooth video streaming
* Ability to change video quality
* Low infrastructure cost
* High availability, scalability, and reliability requirements
* Support mobile apps, web browser, and smart TV

### Back of the envelope estimation
* Product has 5 million daily active users (DAU)
* Users watch 5 videos per day
* 10% of users upload 1 video per day
* Average video size is 300 MB
* Total daily storage space needed: 5 million * 10% * 300 MB = 150TB
* Assume 100% of traffic is served from CDN service, the average cost per GB is $0.02, cost could be 5 million * 5 videos * 0.3GB * $0.02 = $150,000 per day


## Step 2 - Propose high-level design and get buy-in
Reasons of why we choose not to build everything by ourselves:
* Within the limited time frame, choosing the right technology to do a job right is more important than explaining how the technology works in detail. For instance, mentioning blob storage for storing source videos is enough for the interview.
* Building scalable blob storage or CDN is extremely complex and costly, even Netflix or Facebook do not build everything themselves

Three components of system:
* Client: computer, mobile phone, or TV
* CDN: Videos are stored in CDN. When you press play, a video is streamed from the CDN
* API Servers: Everything else except video streaming goes through API servers, including feed recommendation, generating video upload URL, updating metadata database and cache, user signup

### Video uploading flow
* User: A user watches videos on devices, like a computer, mobile phone, or TV
* Load balancer: evenly distributes requests among API servers
* API servers: All user requests go through API servers except video streaming
* Metadata DB: Video metadata are stored in Metadata DB. It is sharded and replicated to meet performance and high availability requirements.
* Metadata cache: video metadata and user objects are cached
* Original storage: A blob storage system is used to store original videos.
* Transcoding servers: Video transcoding is also called video encoding. It is the process of converting a video format to other formats, which provide the best video streams possible for different devices and bandwidth capabilities
* Transcoded storage: It is a blob storage that stores transcoded video files
* CDN: Videos are cached in CDN. When you click the play button, a video is streamed from the CDN
* Completion queue: a message queue that stores information about video transcoding completion events
* Completion handler: a list of workers that pull event data from the completion queue and update metadata cache and database

#### upload the actual video
1. Videos are uploaded to the original storage
2. Transcoding servers fetch videos from the original storage and start transcoding
3. Once transcoding is complete, the following two steps are executed in parallel:
    1. For video storage:
        * Transcoded videos are sent to transcoded storage
        * Transcoded videos are distributed to CDN
    2. For video metadata:
        * Transcoding completion events are queued in the completion queue
        * Workers in completion handler pull event data from the queue, and update the metadata database and cache when video transcoding is complete
4. API servers inform the client that the video is successfully uploaded and is ready for streaming

#### update the metadata
While a file is being uploaded to the original storage, the client in parallel sends a request to update the video metadata. The request contains video metadata, including file name, size, format, etc. API servers update the metadata cache and database

### Video streaming flow
Popular streaming protocols:
* MPEG–DASH
* Apple HLS
* Microsoft Smooth Streaming
* Adobe HTTP Dynamic Streaming

When we design a video streaming service, we have to choose the right streaming protocol to support our use cases.
Videos are streamed from CDN directly. The edge server closest to you will deliver the video. 


## Step 3 - Design deep dive
### Video transcoding
Bitrate is the rate at which bits are processed over time. A higher bitrate generally means higher video quality. High bitrate streams need more processing power and fast internet speed.
Video transcoding is important for the following reasons:
* Raw video consumes large amounts of storage space. An hour-long high definition video recorded at 60 frames per second can take up hundred GB of space
* Many devices and browsers only support certain types of video formats
* deliver higher resolution video to users who have high network bandwidth and lower resolution video to users who have low bandwidth
* To ensure a video is played continuously, switching video quality automatically or manually based on network conditions is essential for smooth user experience

Two parts of encoding format:
* Container: contains the video file, audio, and metadata
* Codecs: compression and decompression algorithms aim to reduce the video size while preserving the video quality

### Directed acyclic graph (DAG) model
To support different video processing pipelines and maintain high parallelism, we need to add some level of abstraction and let client programmers define what tasks to execute. For example, Facebook’s streaming video engine uses a directed acyclic graph (DAG) programming model, which defines tasks in stages so they can be executed sequentially or parallelly. 
the original video is split into video, audio, and metadata. Here are some tasks that can be applied on a video file:
* Inspection: Make sure videos have good quality and are not malformed
* Video encodings: Videos are converted to support different resolutions, codec, bitrates, etc
* Thumbnail: Thumbnails can either be uploaded by a user or automatically generated by the system
* Watermark: An image overlay on top of your video contains identifying information about your video

### Video transcoding architecture
#### Preprocessor
The preprocessor has 4 responsibilities:
1. Video splitting: Video stream is split into smaller Group of Pictures(GOP) alignment. Each chunk is an independently playable unit, usually a few seconds in length.
2. Some old mobile devices or browsers might not support video splitting. Preprocessor split videos by GOP alignment for old clients.
3. DAG generation: The processor generates DAG based on configuration files client programmers write
4. Cache data: The preprocessor is a cache for segmented videos. For better reliability, the preprocessor stores GOPs and metadata in temporary storage. If video encoding fails, the system could use persisted data for retry operations.

#### DAG scheduler
The DAG scheduler splits a DAG graph into stages of tasks and puts them in the task queue in the resource manager. For example, the original video is split into two stages:
1. video, audio, and metadata
2. The video file is split into two tasks
    1. video encoding
    2. thumbnail
3. The audio file requires audio encoding as part of the stage 2 tasks

#### Resource manager
The resource manager is responsible for managing the efficiency of resource allocation:
* Task queue: a priority queue that contains tasks to be executed
* Worker queue: a priority queue that contains worker utilization info
* Running queue: contains info about the running tasks and workers
* Task scheduler: picks the optimal task/worker, and instructs the chosen task worker to execute the job

The resource manager works as follows:
1. gets the highest priority task from the task que
2. gets the optimal task worker to run the task from the worker queue
3. instruct the chosen task worker to run the task
4. binds the task/worker info and puts it in the running queue
5. removes the job from the running queue once the job is done

#### Task workers
Task workers run the tasks which are defined in the DAG. Different task workers may run different tasks.

#### Temporary storage
The choice of storage system depends on factors like data type, data size, access frequency, data life span, etc. For instance:
* memory store: metadata is frequently accessed by workers, and the data size is usually small
* blob storage: for video or audio data

#### Encoded video
Encoded video is the final output of the encoding pipeline

### System optimizations
#### Speed optimization: parallelize video uploading
Uploading a video as a whole unit is inefficient. We can split a video into smaller chunks by GOP alignment. The job of splitting a video file by GOP can be implemented by the client to improve the upload speed. 

#### Speed optimization: place upload centers close to users
setting up multiple upload centers across the globel. 

#### Speed optimization: parallelism everywhere
build a loosely coupled system and enable high parallelism. The flow of how a video is transferred from original storage to the CDN is shown below:

An example to explain how message queues make the system more loosely coupled:
* Before: the encoding module must wait for the output of the download module
* After: the encoding module does not need to wait for the output of the download module anymore

#### Safety optimization: pre-signed upload URL
To ensure only authorized users upload videos to the right location, we introduce pre-signed URLs:
1. client makes a HTTP request to API servers to fetch the pre-signed URL, which gives the access permission to the object identified in the URL. The term pre-signed URL is used by uploading files to Amazon S3. 
2. API servers respond with a pre-signed URL
3. Once the client receives the response, it uploads the video using the pre-signed URL.

#### Safety optimization: protect your videos
To protect copyrighted videos:
* Digital rights management (DRM) systems: Apple FairPlay, Google Widevine, and Microsoft PlayReady
* AES encryption: You can encrypt a video and configure an authorization policy. This ensures that only authorized users can watch an encrypted video
* Visual watermarking: Place an image overlay on top of video that contains identifying information

#### Cost-saving optimization
few optimizations to reduce CDN cost:
* Only serve the most popular videos from CDN, and other videos from our high capacity storage video servers
* For less popular content, we don't need to store many encoded video versions
* Some videos are only popular in certain regions. No need to distribute these videos to other regions.
* Build your own CDN and partner with Internet Service Providers (ISPs).

### Error handling
Two types of errors exist:
* Recoverable error: video segment fails to transcode. Solution: retry the operation a few times; If the task continues to fail, returns a proper error code to the client
* Non-recoverable error: malformed video format, system stops the running tasks associated with the video and returns the proper error code to the client

Typical errors:
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


## Step 4 - Wrap up
additional talking points:
* Scale the API tier: Because API servers are stateless, it is easy to scale API tier horizontally
* Scale the database: You can talk about database replication and sharding
* Live streaming: differences between video and live streaming
    * Live streaming has a higher latency requirement, might need a different streaming protocol
    * Live streaming has a lower requirement for parallelism because small chunks of data are already processed in real-time
    * Live streaming requires different sets of error handling. Error handling shouldn't take too much time
* Video takedowns: Videos that violate copyrights, pornography, or other illegal acts shall be removed

