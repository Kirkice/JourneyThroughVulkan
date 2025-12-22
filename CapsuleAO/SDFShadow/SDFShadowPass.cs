using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SDFShadowPass : ScriptableRenderPass
{
    static readonly string k_RenderTag = "SDF Shadow";
    private RenderTargetHandle destination { get; set; }
    private Material material;
    private RenderTargetIdentifier currentTarget;
    private RenderTargetHandle m_temporaryColorTexture;
    private FilterMode filterMode { get; set; }

    private Vector4[] _frustumCorners = new Vector4[4];
    
    private Texture3D body3d;
    private Texture3D face3d;
    private Texture3D hair3d;
    private Texture3D weapon3d;
    public SDFShadowPass(SDFShadowFeature.Setting setting)
    {
        material = CoreUtils.CreateEngineMaterial(Shader.Find("Hidden/sdf_shadow"));
        m_temporaryColorTexture.Init("temporaryColorTexture");

        this.body3d = setting.body3d;
        this.face3d = setting.face3d;
        this.hair3d = setting.hair3d;
        this.weapon3d = setting.weapon3d;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        cameraTextureDescriptor.colorFormat = RenderTextureFormat.Default;
        ConfigureClear(ClearFlag.All, Color.black);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (material == null)
            return;

        var cmd = CommandBufferPool.Get(k_RenderTag);
        Render(cmd, ref renderingData);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        if(body3d == null || face3d == null || hair3d == null || weapon3d == null)
            return;
        
        var camera = renderingData.cameraData.camera;
        
        var source = currentTarget;
        RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
        opaqueDesc.depthBufferBits = 0;

        // setup frustum corners for world position reconstruction
        // bottom left
        _frustumCorners[0] = camera.ViewportToWorldPoint(new Vector3(0, 0, camera.farClipPlane));
        // top left
        _frustumCorners[2] = camera.ViewportToWorldPoint(new Vector3(0, 1, camera.farClipPlane));
        // top right
        _frustumCorners[3] = camera.ViewportToWorldPoint(new Vector3(1, 1, camera.farClipPlane));
        // bottom right
        _frustumCorners[1] = camera.ViewportToWorldPoint(new Vector3(1, 0, camera.farClipPlane));

        material.SetVectorArray("_FrustumCorners", _frustumCorners);
        material.SetVector("_CameraForward", camera.transform.forward);
        
        material.SetTexture("_Body3D", body3d);
        // material.SetTexture("_Face3D", face3d);
        // material.SetTexture("_Hair3D", hair3d);
        // material.SetTexture("_Weapon3D", weapon3d);

        cmd.GetTemporaryRT(m_temporaryColorTexture.id, opaqueDesc, filterMode);
        Blit(cmd, source, m_temporaryColorTexture.Identifier(), material);
        cmd.SetGlobalTexture("_SDFShadowTex",m_temporaryColorTexture.id);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        if (destination == RenderTargetHandle.CameraTarget)
            cmd.ReleaseTemporaryRT(m_temporaryColorTexture.id);
    }

    public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
    {
        this.destination = dest;
        this.currentTarget = currentTarget;
    }
}