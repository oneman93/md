* Planner document to push md files to moh93 homepage
* 
* 
* 
```
// 1a. local -> working
http://127.0.0.1:5500/md/md.htm

// 1b. moh93 -> works
https://home.moh93.com/md-project/md.htm?src=https%3A%2F%2Fhome.moh93.com%2FDoc%3Fhandler%3DMarkdown%26key%3D_work-index.md

// 2a. local -> works
http://127.0.0.1:5500/md/md.htm?src=_LoadingDocuments%2Fmdhtm-loading.md

// 2b. moh93 -> not works
https://home.moh93.com/_LoadingDocuments/mdhtm-loading.md

// 2b. moh93 -> works
https://home.moh93.com/md-project/md.htm?src=https%3A%2F%2Fhome.moh93.com%2FDoc%3Fhandler%3DMarkdown%26key%3D_LoadingDocuments%2Fmdhtm-loading.md

```

# Issue: Make a correct path

* It seems each file in s3 has a s3 key:
* * See [workIndex.png](./imgs/img-moh93/workIndex.png)
* [mdhtm.png](./imgs/img-moh93/mdhtm.png)
* [urlIncode.png](./imgs/img-moh93/urlIncode.png)
* This s3 key becomes complicated with URLEncode

* It is full path from root foler
* eg, `_work-index.md`
* eg, `_LoadingDocuments/mdhtm-loading.md`
* So to make a correct path, you have to:
```
https://home.moh93.com/md-project/md.htm?src=https%3A%2F%2Fhome.moh93.com%2FDoc%3Fhandler%3DMarkdown%26key%3D{s3key}
```
* This is too complicated url.

# DynamoDB

* Each document is either public or private (password encrypted).
* Password encrypted document has metatag on top of the doucment with key `ddb-key`.
* `ddb-key` means dynamodb-key
* See [passEncrypted1.png](./imgs/img-moh93/passEncrypted1.png)
* [passEncrypted2.png](./imgs/img-moh93/passEncrypted2.png)
* It is currently working
* [dynamo-values.png](./imgs/img-moh93/dynamo-values.png)

# Resources

* [cursor-share-doc-options.md](../../AWSServerlessPersonal/cursor-share-doc-options.md)
