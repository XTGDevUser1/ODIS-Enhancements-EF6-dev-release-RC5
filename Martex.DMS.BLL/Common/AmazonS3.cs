
using Amazon.S3;
using Amazon.S3.Model;
using System;
using System.Configuration;
using System.IO;
using System.Net;
using System.Net.Http;

namespace Amazon.S3
{
    public class GenPresignedURL
    {
        public static readonly RegionEndpoint bucketRegion = RegionEndpoint.USEast1;
        public static IAmazonS3 s3Client;
        
        public static string GeneratePreSignedURL(string objectKey)
        {
            string RecordingLocation = objectKey;
            var bucketAndKey = RecordingLocation.Split(new[] { '/' }, 2);
            s3Client = new AmazonS3Client(bucketRegion);
            string urlString = "";
            try
            {
                GetPreSignedUrlRequest request1 = new GetPreSignedUrlRequest
                {
                    BucketName = bucketAndKey[0],
                    Key = bucketAndKey[1],
                    Expires = DateTime.Now.AddMinutes(60)
                };

                urlString = s3Client.GetPreSignedURL(request1);
            }
            catch (AmazonS3Exception e)
            {
                Console.WriteLine("Error encountered on server. Message:'{0}' when writing an object", e.Message);
            }
            catch (Exception e)
            {
                Console.WriteLine("Unknown encountered on server. Message:'{0}' when writing an object", e.Message);
            }
            return urlString;
        }
    }
}