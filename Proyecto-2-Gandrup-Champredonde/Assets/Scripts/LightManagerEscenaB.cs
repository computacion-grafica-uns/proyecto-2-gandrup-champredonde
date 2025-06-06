using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LigthManagerEscenaB : MonoBehaviour
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
    public float spotActiva = 1f;
    public float dirActiva = 1f;
    public float pointActiva = 1f;
    // Start is called before the first frame update
    private Vector4 posCam;
    public float moveSpeed = 5f;
    public float mouseSensitivity = 2f;
    private GameObject camPP;
    //Camara Orbital
    private GameObject camOrbital;
    private GameObject targetOrbital;
    private float x = 0.0f, y = 20.0f;
    private float distance = 5.0f;
    private float yMinLimit = -20f, yMaxLimit = 80f;
    private float xSpeed = 120.0f, ySpeed = 80.0f;
    private float yaw = 0f;

    //Lista de Objetos observables con la Camara Orbital
    public GameObject[] objetivosOrbitales;
    private int indiceObjActual = 0;
    void Start()
    {
        createCamara();
        createCamaraOrbital();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.C))
        {
            bool estabaEnPP = camPP.activeSelf;

            // 1. Desactivar audio listeners
            var listenerPP = camPP.GetComponent<AudioListener>();
            var listenerOrb = camOrbital.GetComponent<AudioListener>();
            if (listenerPP) listenerPP.enabled = false;
            if (listenerOrb) listenerOrb.enabled = false;

            // 2. Desactivar ambas cámaras
            camPP.SetActive(false);
            camOrbital.SetActive(false);

            // 3. Activar solo una cámara con su listener
            if (estabaEnPP)
            {
                camOrbital.SetActive(true);
                if (listenerOrb) listenerOrb.enabled = true;
            }
            else
            {
                camPP.SetActive(true);
                if (listenerPP) listenerPP.enabled = true;
            }

            Debug.Log("Cambié a " + (estabaEnPP ? "Orbital" : "Primera Persona"));
        }

        // Movimiento orbital
        if (camOrbital != null && camOrbital.activeSelf)
        {
            ControlOrbital();
            if (Input.GetKeyDown(KeyCode.O))
            {
                CambiarObjetivoOrbital();
                Debug.Log("Nuevo objetivo orbital: " + objetivosOrbitales[indiceObjActual].name);
            }
        }
           

        // Movimiento FPS
        if (camPP != null && camPP.activeSelf)
            camaraPP();

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

    private void camaraPP(){
        if (camPP.GetComponent<AudioListener>() == null)
            camPP.AddComponent<AudioListener>();
        float moveX = Input.GetAxis("Horizontal");
        float moveZ = Input.GetAxis("Vertical");

        Vector3 move = camPP.transform.right * moveX + camPP.transform.forward * moveZ;
        camPP.transform.position += move * moveSpeed * Time.deltaTime;
        if(Input.GetMouseButton(0))    
            yaw += Input.GetAxis("Mouse X") * mouseSensitivity;
        camPP.transform.eulerAngles = new Vector3(0, yaw, 0);
        Vector3 posC = camPP.transform.position;
        posCam = new Vector4(posC.x, posC.y, posC.z, 1);
    }

    private void createCamara()
    {
        camPP = new GameObject("FPSCamera");
        camPP.tag = "MainCamera";
        camPP.transform.position = new Vector3(0, 10, 0);
        camPP.AddComponent<Camera>();
        if (camPP.GetComponent<AudioListener>() == null)
            camPP.AddComponent<AudioListener>();

    }

    private void createCamaraOrbital()
    {
        // Crear objeto target al que orbitamos
        targetOrbital = new GameObject("TargetOrbital");
        targetOrbital.transform.position = new Vector3(0, 9, 0);

        // Crear la cámara orbital
        camOrbital = new GameObject("CameraOrbital");
        Camera orbitalCamComp = camOrbital.AddComponent<Camera>();

        if (camOrbital.GetComponent<AudioListener>() == null)
            camOrbital.AddComponent<AudioListener>();

        camOrbital.tag = "MainCamera";
        camOrbital.SetActive(false);

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
        distance = Mathf.Clamp(distance - scroll * 5, 2f, 100f);

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
}
