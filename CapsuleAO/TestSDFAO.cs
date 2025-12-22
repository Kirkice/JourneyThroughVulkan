using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestSDFAO : MonoBehaviour
{
    public GameObject cube;
    private void Start()
    {
        Shader.SetGlobalVector("_CubePos",cube.transform.position);
        Shader.SetGlobalVector("_CubeScale",cube.transform.localScale);
    }
    
    private void Update()
    {
        Shader.SetGlobalVector("_CubePos",cube.transform.position);
        Shader.SetGlobalVector("_CubeScale",cube.transform.localScale);
    }
}
