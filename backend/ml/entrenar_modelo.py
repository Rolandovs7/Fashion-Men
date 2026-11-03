#!/usr/bin/env python3
"""
[Segundo Parcial] CU24 - Machine Learning (Modelo Predictivo)
Entrena un modelo de Regresión Lineal para predecir ventas del próximo mes.
"""
import os
import sys
import json
from datetime import datetime, timedelta

import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression


def generar_datos_sinteticos():
    meses = []
    ventas = []
    base = 15000
    for i in range(12):
        fecha = datetime.now() - timedelta(days=30 * (11 - i))
        mes = fecha.strftime("%Y-%m")
        v = base + i * 800 + np.random.randint(-500, 1500)
        meses.append(mes)
        ventas.append(float(max(5000, v)))
    return meses, ventas


def entrenar():
    meses, ventas = generar_datos_sinteticos()
    df = pd.DataFrame({"mes": meses, "ventas": ventas})
    df["t"] = range(len(df))
    X = df[["t"]]
    y = df["ventas"]
    modelo = LinearRegression()
    modelo.fit(X, y)
    siguiente_t = len(df)
    pred = float(modelo.predict(np.array([[siguiente_t]]))[0])
    pred = max(1000, pred)
    proximo = (datetime.now() + timedelta(days=30)).strftime("%Y-%m")
    resultado = {
        "historico": [{"mes": m, "ventas": v} for m, v in zip(meses, ventas)],
        "prediccion": {"mes": proximo, "ventas": round(pred, 2)},
        "entrenado_en": datetime.now().isoformat()
    }
    out = os.path.join(os.path.dirname(__file__), "modelo_prediccion.json")
    with open(out, "w") as f:
        json.dump(resultado, f, ensure_ascii=False, indent=2)
    print(json.dumps(resultado))
    return resultado


if __name__ == "__main__":
    entrenar()
