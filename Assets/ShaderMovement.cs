using UnityEngine;

public class ShaderMovement : MonoBehaviour
{
    void Update()
    {
        Material material = GetComponent<Renderer>().material;
        material.SetVector("_Position", transform.position);
    }
}
