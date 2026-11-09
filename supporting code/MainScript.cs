using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class MainScript : MonoBehaviour
{

    // set which test to run
    // 1 = plane angle varies, 2 = plane color varies
    int test = 1;

    // game objects
    private GameObject dirLight, testPlane;

    float param;                             // stimulus parameter (angle, color, or distance)
    float[] param_array = new float[1024];   // time course of the parameter
    float[,] rgb_array = new float[1024,3];  // time course of rendered rgb value
    int i = 0;                               // index into above arrays

    int frameCount = 0;             // running count of number of frames rendered
    bool waitingForRender = false;  // flag whether we're currently waiting for a frame to render

    // rotate plane around vertical axis
    void SetPlaneAngle(float x)
    {
        testPlane.transform.rotation = Quaternion.Euler( -90.0f, 0.0f, x );
    }

    // set achromatic color of plane
    void SetPlaneRGB(int x)
    {    
        float xf = (float)x/255.0f;
        Color c = new Color(xf,xf,xf,1);
        Material m = testPlane.GetComponent<Renderer>().material;
        m.color = c;
    }

    // runs once at start
    void Start()
    {
        // find game objects
        dirLight = GameObject.Find("Directional Light");
        testPlane = GameObject.Find("Plane");

        // configure lighting and initialize stimulus parameter
        if( test == 1 )
        {
            param = -85.0f;
            SetPlaneAngle( param );
        }
        else if( test==2 )
        {
            param = 0.0f;
            SetPlaneRGB( (int)param );
        }
    }

    // runs on every frame
    void Update()
    {
        // wait for a short burn-in period before beginning test
        int frameWait = 10;
        if( ++frameCount < frameWait )
            return;
        
        // start first frame capture
        if( frameCount == frameWait )
        {
            StartCoroutine( Capture() );
            return;
        }

        // wait for frame to be rendered and RGB to be recorded
        if( waitingForRender )
            return;

        // adjust stimulus parameter
        bool done = false;
        if( test == 1 )
        {
            param += 1.0f;
            SetPlaneAngle( param );
            done = param > 85.0f;
        }
        else if( test==2 )
        {
            param += 1.0f;
            SetPlaneRGB( (int)param );
            done = param > 255;
        }

        // if we're done, write data to file and quit
        if( done )
        {
            StreamWriter sr = System.IO.File.CreateText( "data.txt" );
            for( int j = 0; j < i; j++ )
                sr.WriteLine( "{0},{1},{2},{3}",param_array[j],rgb_array[j,0],rgb_array[j,1],rgb_array[j,2] );
            sr.Close();
            UnityEditor.EditorApplication.isPlaying = false;
            return;
        }

        // start frame capture
        StartCoroutine( Capture() );

    }

    // record rgb value at middle of screen
    IEnumerator Capture()
    {
        // wait until frame is rendered
		waitingForRender = true;
        yield return new WaitForEndOfFrame();

        // get a one-pixel texture from the centre of the screen
        var tex = new Texture2D( 1, 1, TextureFormat.RGB24, false );
        tex.ReadPixels( new Rect( Screen.width/2, Screen.height/2, 1, 1 ), 0, 0 );
        tex.Apply();
        var pix = tex.GetPixels32();
        Destroy( tex );

        // record parameter and rgb value
        param_array[i] = param;
        rgb_array[i,0] = pix[0].r;
        rgb_array[i,1] = pix[0].g;
        rgb_array[i++,2] = pix[0].b;
        waitingForRender = false;

        // can also record screenshots here for later analysis
        // ScreenCapture.CaptureScreenshot( System.String.Format( "screen{0}.png", i ) );
    }

}

