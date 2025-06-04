using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightManagerEscenaA : MonoBehaviour
{
    public Material[] materiales;
    
    //Luz direccional
    public Vector3 DirLightColor ;
    public Vector3 DirLightDirection;
    //Luz spot
    public Vector4 SpotLightColor;
    public Vector4 SpotLightDirection;
    public Vector4 SpotLightPosition;
    public float SpotLightApertura;
    //Luz puntual
    public Vector4 PointLightColor;
    public Vector4 PointLightPosition;
    //Seteo de luces inicial 
    private float spotActiva = 1f;
    private float dirActiva = 1f;
    private float pointActiva = 1f;
    // Start is called before the first frame update

    //Camara Orbital
    private GameObject camOrbital;
    private GameObject targetOrbital;
    private Vector4 posCam;
    private float x = 0.0f, y = 20.0f;
    private float distance = 5.0f;
    private float yMinLimit = -20f, yMaxLimit = 80f;
    private float xSpeed = 120.0f, ySpeed = 80.0f;

    //Lista de Objetos observables con la Camara Orbital
    public GameObject[] objetivosOrbitales;
    private int indiceObjActual = 0;
    void Start()
    {
        createCamaraOrbital();
    }

    // Update is called once per frame
    void Update()
    {
        

        // Cambio de objetos
            ControlOrbital();
            if (Input.GetKeyDown(KeyCode.O))
            {
                CambiarObjetivoOrbital();
                Debug.Log("Nuevo objetivo orbital: " + objetivosOrbitales[indiceObjActual].name);
            }

        //Centralizar en el origen 
        if (Input.GetKeyDown(KeyCode.Space))
        {
            CentrarOrbitalEnOrigen();
        }

        // Actualizacion de las luces de la Escena
        if (Input.GetKeyDown(KeyCode.J))
            spotActiva = 1f - spotActiva;

        if (Input.GetKeyDown(KeyCode.K))
            dirActiva = 1f - dirActiva;

        if (Input.GetKeyDown(KeyCode.L))
            pointActiva = 1f - pointActiva;


        actualizarMateriales();
    }

    private void actualizarMateriales()
    {
        foreach(Material m in materiales){
            m.SetVector("_CameraPosition_w",posCam);
            m.SetVector("_DirLightDirection",DirLightDirection);
            m.SetVector("_DirLightColor",DirLightColor);
            m.SetVector("_PointLightPosition",PointLightPosition);
            m.SetVector("_PointLightColor",PointLightColor);
            m.SetVector("_SpotLightDirection",SpotLightDirection);
            m.SetVector("_SpotLightPosition",SpotLightPosition);
            m.SetVector("_SpotLightColor",SpotLightColor);
            m.SetFloat("_SpotLightApertura",SpotLightApertura);
            m.SetFloat("_SpotActiva", spotActiva);
            m.SetFloat("_DirActiva", dirActiva);
            m.SetFloat("_PointActiva", pointActiva);
        }
    }

    private void createCamaraOrbital()
    {
        // Crear objeto target al que orbitamos
        targetOrbital = new GameObject("TargetOrbital");
        targetOrbital.transform.position = new Vector3(0, 1, 0);

        // Crear la cámara orbital
        camOrbital = new GameObject("CameraOrbital");
        Camera orbitalCamComp = camOrbital.AddComponent<Camera>();

        if (camOrbital.GetComponent<AudioListener>() == null)
            camOrbital.AddComponent<AudioListener>();

        camOrbital.tag = "MainCamera";
        camOrbital.SetActive(true);

        x = 0f;
        y = 20f;
        distance = 5f;

        UpdateOrbitalCameraTransform();
    }

    private void ControlOrbital()
    {
        x += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
        y -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f;
        y = Mathf.Clamp(y, yMinLimit, yMaxLimit);

        float scroll = Input.GetAxis("Mouse ScrollWheel");
        distance = Mathf.Clamp(distance - scroll * 5, 2f, 200f);

        UpdateOrbitalCameraTransform();
    }

    private void UpdateOrbitalCameraTransform()
    {
        Quaternion rotation = Quaternion.Euler(y, x, 0);
        Vector3 negDistance = new Vector3(0, 0, -distance);
        Vector3 position = rotation * negDistance + targetOrbital.transform.position;

        camOrbital.transform.position = position;
        camOrbital.transform.rotation = rotation;
        posCam = new Vector4(position.x, position.y, position.z, 0);
    }

    private void CambiarObjetivoOrbital()
    {
        if (objetivosOrbitales.Length == 0) return;
        indiceObjActual = (indiceObjActual + 1) % objetivosOrbitales.Length;
        targetOrbital.transform.position = objetivosOrbitales[indiceObjActual].transform.position;
    }

    private void CentrarOrbitalEnOrigen()
    {
        targetOrbital.transform.position = Vector3.zero;
        UpdateOrbitalCameraTransform();
    }
}
