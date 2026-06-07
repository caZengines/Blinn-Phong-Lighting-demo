struct VertexInput {
    float3 inPosition;
    float2 inTexCoord;
    float3 inNormal;
};

struct Light {
    float4 position;
    float4 color;
    float intensity;
}

struct UniformBuffer {
    float4x4 model;
    float4x4 view;
    float4x4 proj;

    float4 cameraPos;
    Light light;
};
ConstantBuffer<UniformBuffer> ubo;

struct VertexOutput {
    float4 pos : SV_Position;
    float2 fragTexCoord;
    float3 worldNormal;
    float3 worldPos;
};

[shader("vertex")]
VertexOutput vertMain(VertexInput Input) {
    VertexOutput Output;

    float4 worldPosition = mul(ubo.model, float4(Input.inPosition, 1.0));

    Output.pos = mul(ubo.proj, mul(ubo.view, mul(ubo.model, float4(Input.inPosition, 1.0))));
    Output.fragTexCoord = Input.inTexCoord;
    Output.worldPos = worldPosition.xyz;
    Output.worldNormal = normalize(mul(float3x3(ubo.model), Input.inNormal));
    
    return Output;
}

Sampler2D texture;

[shader("fragment")]
float4 fragMain(VertexOutput inVert) : SV_Target {
    //Sample texture
    float4 albedo = texture.Sample(inVert.fragTexCoord);

    float3 n = inVert.worldNormal;

    float3 lightDir = normalize(ubo.light.position.xyz - inVert.worldPos);
    float3 viewDir = normalize(ubo.cameraPos.xyz - inVert.worldPos);
    float3 halfwayDir = normalize(lightDir + viewDir);

    // dot light
    float dist = length(ubo.light.position.xyz - inVert.worldPos);
    float atten = 1.0;
    float3 radiance = ubo.light.color.rgb * ubo.light.intensity * atten;

    // Ambient
    float3 ambient = 0.05 * albedo.rgb;

    // Diffuse(lambert)
    float diff = max(dot(n, lightDir), 0.0);
    float3 diffuse = albedo.rgb * diff;

    // Specular
    float shininess = 20.0;
    float spec = max(dot(n, halfwayDir), 0.0);
    float3 specular = pow(spec, shininess);

    float3 finalColor = (ambient + diffuse + specular) * radiance;

    return float4(finalColor, albedo.a);
}
