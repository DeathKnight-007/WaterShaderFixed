using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{
    public Material mat;
    private List<int> indexs = new List<int>();
    private void Start()
    {
        indexs.Add(1);
        indexs.Add(2);
        indexs.Add(3);
    }
    void Update()
    {       
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition + Vector3.forward * 10);
            RaycastHit hit;
            if(Physics.Raycast(ray, out hit,100))
            {
                if (indexs.Count > 0)
                {
                    int t = indexs[0];
                    mat.SetVector("_DropPos_" + t, hit.point);
                    mat.SetFloat("_NowTime_" + t, Time.time);                   
                    mat.SetFloat("_SplashScale_" + t, Random.Range(0.5f, 2f));
                    indexs.RemoveAt(0);
                    StartCoroutine(WaitAddIE(t));                   
                }
            }           
        }        
    }
    private IEnumerator WaitAddIE(int id)
    {
        yield return new WaitForSeconds(1);
        indexs.Add(id);
    }
}
