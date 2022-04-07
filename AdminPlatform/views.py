import pathlib, os, sys
RESOURCES = str(pathlib.Path(__file__).parent.parent.resolve())

from django.shortcuts import render, redirect
from django.http import HttpResponse, HttpResponseNotFound
from . import models

import rest_framework.views as RestViews
import rest_framework.parsers as RestParsers
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle

import datetime
import uuid
import pickle

DATABASE_PATH = os.environ.get('DATASERVER_PATH')

# Create your views here.
def index(request):
    if not "is_authenticated" in request.session:
        return redirect("/auth")

    if not request.session["is_authenticated"]:
        return redirect("/auth")

    context = dict()
    return render(request, 'index.html', context=context)

class Verification(RestViews.APIView):
    parser_classes = [RestParsers.MultiPartParser, RestParsers.FormParser]

    def get(self, request):
        if "is_authenticated" in request.session:
            if request.session["is_authenticated"]:
                return redirect("/")

        context = dict()
        return render(request, 'auth.html', context=context)

    def post(self, request):
        if "verificationCode" in request.data:
            print(request.data["verificationCode"])
            if request.data["verificationCode"] == "123456":
                request.session["is_authenticated"] = True
                request.session.save()
                return Response(status=200)

        return Response(status=403)

class ServerInformation(RestViews.APIView):
    parser_classes = [RestParsers.MultiPartParser, RestParsers.FormParser]

    def post(self, request):
        if not "is_authenticated" in request.session:
            return Response(status=404)

        if not request.session["is_authenticated"]:
            return Response(status=404)

        if "file" in request.data:
            rawBytes = request.data["file"].read()
            if os.path.exists(DATABASE_PATH + request.data["port"] + os.path.sep + request.data["file"].name):
                return Response(status=403)

            with open(DATABASE_PATH + request.data["port"] + os.path.sep + request.data["file"].name, "wb+") as file:
                file.write(rawBytes)
            return Response(status=200)

        if "removeFile" in request.data:
            if not os.path.exists(DATABASE_PATH + request.data["port"] + os.path.sep + request.data["removeFile"]):
                return Response(status=403)

            os.remove(DATABASE_PATH + request.data["port"] + os.path.sep + request.data["removeFile"])
            return Response(status=200)

        data = {"ServerPort": list()}
        directoryContents = os.listdir(DATABASE_PATH)
        for content in directoryContents:
            if os.path.isdir(DATABASE_PATH + content):
                data["ServerPort"].append(content)
                data[content] = list()
                contentFiles = os.listdir(DATABASE_PATH + content)
                for contentFile in contentFiles:
                    fileInfo = os.stat(DATABASE_PATH + content + os.path.sep + contentFile)
                    data[content].append({"Filename": contentFile, "Size": fileInfo.st_size, "Date": fileInfo.st_mtime})

        return Response(status=200, data=data)
