using UnityEngine;

public class ColourChange1 : MonoBehaviour
{
    private Material blobMaterial;
    private Material metalMaterial;
    public GameObject lamp;
    public GameObject metal;
    public FlexibleColorPicker colorPicker1;
    public FlexibleColorPicker colorPicker2;
    public FlexibleColorPicker colorPicker3;

    void Start()
    {
        blobMaterial = lamp.GetComponent<Renderer>().material;
        metalMaterial = metal.GetComponent<Renderer>().material;
    }
    
    void Update()
    {
        blobMaterial.SetColor("_Color1", colorPicker1.color);
        blobMaterial.SetColor("_Color2", colorPicker2.color);
        metalMaterial.color = colorPicker3.color;
    }
}
