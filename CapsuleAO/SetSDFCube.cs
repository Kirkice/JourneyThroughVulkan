using System;
using System.Collections;
using System.Collections.Generic;
using AmplifyShaderEditor;
using UnityEngine;

public class SetSDFCube : MonoBehaviour
{
    public GameObject[] _objects = new GameObject[4];

    private void Start()
    {
        Matrix4x4[] inverse_array = new Matrix4x4[4];
        Vector4[] half_extents_array = new Vector4[4];
        Vector4[] os_center_array = new Vector4[4];
        Vector4[] ws_center_array = new Vector4[4];
        Vector4[] ws_axis_array = new Vector4[12];
        float[] sdf_idx_array = new float[4];
        
        for (int i = 0; i < _objects.Length; i++)
        {
            Matrix4x4 trs = Matrix4x4.TRS(_objects[i].transform.position, _objects[i].transform.rotation,
                _objects[i].transform.localPosition);
            Matrix4x4 invers_trs = Matrix4x4.Inverse(trs);
            Vector4 half_extent = _objects[i].transform.GetBounds().extents;
            Vector4 os_center = Vector4.zero;
            Vector4 ws_center = _objects[i].transform.position;

            inverse_array[i] = invers_trs;
            half_extents_array[i] = half_extent;
            os_center_array[i] = os_center;
            ws_center_array[i] = ws_center;
            
            Vector3[] axis = {
                new Vector3(1.0f, 0.0f, 0.0f),
                new Vector3(0.0f, 1.0f, 0.0f),
                new Vector3(0.0f, 0.0f, 1.0f)
            };
            
            for (int j = 0; j < 3; j++)
                ws_axis_array[i * 3 + j] = trs * axis[j];

            sdf_idx_array[i] = i;
        }
        
        Shader.SetGlobalMatrixArray("_inverse_transform_array", inverse_array);
        Shader.SetGlobalVectorArray("_half_extents_array", half_extents_array);
        Shader.SetGlobalVectorArray("_os_center_array", os_center_array);
        Shader.SetGlobalVectorArray("_ws_center_array", ws_center_array);
        Shader.SetGlobalVectorArray("_ws_axis_array", ws_axis_array);
        Shader.SetGlobalFloatArray("_sdf_idx_array", sdf_idx_array);
    }
}
