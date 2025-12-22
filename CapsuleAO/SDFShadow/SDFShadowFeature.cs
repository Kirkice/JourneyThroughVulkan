using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SDFShadowFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Setting
    {
        public Texture3D body3d;
        public Texture3D face3d;
        public Texture3D hair3d;
        public Texture3D weapon3d;
    }
    public Setting setting = new Setting();
    
    private SDFShadowPass m_SDFShadowPass;
    public override void Create()
    {
        m_SDFShadowPass = new SDFShadowPass(setting);
        m_SDFShadowPass.renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var dest =  RenderTargetHandle.CameraTarget;
        m_SDFShadowPass.Setup(renderer.cameraColorTarget, dest);
        renderer.EnqueuePass(m_SDFShadowPass);
    }
}
