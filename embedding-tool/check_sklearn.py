try:
    import sklearn
    from sklearn.cluster import KMeans
    print("scikit-learn is installed")
except ImportError:
    print("scikit-learn is NOT installed")
